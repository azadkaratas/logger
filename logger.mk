################################################################################
#
# logger
#
################################################################################

LOGGER_VERSION = 1.0
LOGGER_SITE = $(LOGGER_PKGDIR)
LOGGER_SITE_METHOD = local
LOGGER_INSTALL_STAGING = YES
LOGGER_INSTALL_TARGET = YES
LOGGER_DEPENDENCIES = nodejs host-nodejs host-python3

# Define compiler and linker flags for liblogger.so
LOGGER_CFLAGS = $(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -fPIC
LOGGER_LDFLAGS = $(TARGET_LDFLAGS) -shared

define LOGGER_PRE_BUILD_CMDS
	# Install node-addon-api and node-gyp in host environment
	$(HOST_DIR)/bin/npm install node-addon-api@7.1.1 node-gyp@11.2.0 \
		--prefix=$(HOST_DIR)/usr/lib/node_modules \
		--no-save \
		|| (echo "Failed to install node-addon-api or node-gyp"; exit 1)
	# Verify toolchain
	$(TARGET_CC) --version
	# Check environment
	echo "TARGET_CC: $(TARGET_CC)"
	echo "TARGET_CFLAGS: $(TARGET_CFLAGS)"
endef

define LOGGER_BUILD_CMDS
	# Generate Node.js addon code
	$(HOST_DIR)/bin/python3 $(@D)/generate_node_wrapper.py $(@D)

	# Build liblogger.so
	$(TARGET_CC) $(LOGGER_CFLAGS) -c $(@D)/logger.c -o $(@D)/logger.o
	$(TARGET_CC) $(LOGGER_LDFLAGS) $(@D)/logger.o -o $(@D)/liblogger.so
	# Verify liblogger.so architecture
	file $(@D)/liblogger.so

	# Build Node.js addon
	NODE_PATH=$(HOST_DIR)/usr/lib/node_modules \
	CC=$(TARGET_CC) CXX=$(TARGET_CXX) \
	$(HOST_DIR)/bin/node $(HOST_DIR)/usr/lib/node_modules/node-gyp/bin/node-gyp.js configure \
		--nodedir=$(HOST_DIR)/usr \
		--target=aarch64 \
		--arch=aarch64 \
		--directory=$(@D) \
		--python=/usr/bin/python3
	NODE_PATH=$(HOST_DIR)/usr/lib/node_modules \
	CC=$(TARGET_CC) CXX=$(TARGET_CXX) \
	$(HOST_DIR)/bin/node $(HOST_DIR)/usr/lib/node_modules/node-gyp/bin/node-gyp.js build \
		--nodedir=$(HOST_DIR)/usr \
		--jobs=$(PARALLEL_JOBS) \
		--directory=$(@D)
endef

define LOGGER_INSTALL_STAGING_CMDS
	$(INSTALL) -d -m 755 $(STAGING_DIR)/usr/lib64
	$(INSTALL) -d -m 755 $(STAGING_DIR)/usr/include/logger
	$(INSTALL) -D -m 755 $(@D)/liblogger.so $(STAGING_DIR)/usr/lib64/liblogger.so
	$(INSTALL) -D -m 644 $(@D)/logger.h $(STAGING_DIR)/usr/include/logger/logger.h
endef

define LOGGER_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 755 $(TARGET_DIR)/usr/lib64
	$(INSTALL) -d -m 755 $(TARGET_DIR)/usr/include/logger
	$(INSTALL) -D -m 755 $(@D)/liblogger.so $(TARGET_DIR)/usr/lib64/liblogger.so
	$(INSTALL) -D -m 644 $(@D)/logger.h $(TARGET_DIR)/usr/include/logger/logger.h
	$(INSTALL) -d -m 755 $(TARGET_DIR)/usr/lib/node_modules/logger
	$(INSTALL) -D -m 755 $(@D)/build/Release/logger.node $(TARGET_DIR)/usr/lib/node_modules/logger/logger.node
endef

$(eval $(generic-package))