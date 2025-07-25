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
LOGGER_DEPENDENCIES = $(if $(BR2_PACKAGE_LOGGER_NODEJS),host-nodejs host-python3)

# Define compiler and linker flags for liblogger.so
LOGGER_CFLAGS = $(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -fPIC
LOGGER_LDFLAGS = $(TARGET_LDFLAGS) -shared

define LOGGER_BUILD_CMDS
	@echo "Starting LOGGER_BUILD_CMDS"

	# Build liblogger.so
	$(TARGET_CC) $(LOGGER_CFLAGS) -c $(@D)/logger.c -o $(@D)/logger.o \
		|| (echo "Failed to compile logger.c"; exit 1)
	$(TARGET_CC) $(LOGGER_LDFLAGS) $(@D)/logger.o -o $(@D)/liblogger.so \
		|| (echo "Failed to link liblogger.so"; exit 1)
	# Verify liblogger.so
	[ -f $(@D)/liblogger.so ] || (echo "liblogger.so not generated"; exit 1)
	file $(@D)/liblogger.so

	# Install liblogger.so to staging
	$(INSTALL) -d -m 755 $(STAGING_DIR)/usr/lib64
	$(INSTALL) -D -m 755 $(@D)/liblogger.so $(STAGING_DIR)/usr/lib64/liblogger.so \
		|| (echo "Failed to install liblogger.so to staging"; exit 1)
	# Verify staging liblogger.so
	[ -f $(STAGING_DIR)/usr/lib64/liblogger.so ] || (echo "liblogger.so not in staging directory"; exit 1)

	# Node.js addon build steps (only if BR2_PACKAGE_LOGGER_NODEJS is enabled)
	if [ "$(BR2_PACKAGE_LOGGER_NODEJS)" = "y" ]; then \
		$(HOST_DIR)/bin/npm --version || (echo "npm not found"; exit 1); \
		rm -rf $(HOST_DIR)/usr/lib/node_modules/node-addon-api; \
		rm -rf $(HOST_DIR)/usr/lib/node_modules/node-gyp; \
		$(HOST_DIR)/bin/npm install node-addon-api@7.1.1 node-gyp@11.2.0 \
			--prefix=$(HOST_DIR)/usr/lib \
			--no-save \
			|| (echo "Failed to install node-addon-api or node-gyp"; exit 1); \
		[ -d $(HOST_DIR)/usr/lib/node_modules/node-addon-api ] || (echo "node-addon-api not installed in $(HOST_DIR)/usr/lib/node_modules"; exit 1); \
		[ -f $(HOST_DIR)/usr/lib/node_modules/node-gyp/bin/node-gyp.js ] || (echo "node-gyp not installed in $(HOST_DIR)/usr/lib/node_modules"; exit 1); \
		$(HOST_DIR)/bin/python3 $(@D)/generate_node_wrapper.py $(@D) \
			|| (echo "Failed to generate logger_node.c"; exit 1); \
		NODE_PATH=$(HOST_DIR)/usr/lib/node_modules:$(HOST_DIR)/usr/lib/node_modules/npm/node_modules \
		CC=$(TARGET_CC) CXX=$(TARGET_CXX) \
		$(HOST_DIR)/bin/node $(HOST_DIR)/usr/lib/node_modules/node-gyp/bin/node-gyp.js configure \
			--nodedir=$(HOST_DIR)/usr \
			--target=aarch64 \
			--arch=aarch64 \
			--directory=$(@D) \
			--python=/usr/bin/python3 \
			|| (echo "node-gyp configure failed"; exit 1); \
		NODE_PATH=$(HOST_DIR)/usr/lib/node_modules:$(HOST_DIR)/usr/lib/node_modules/npm/node_modules \
		CC=$(TARGET_CC) CXX=$(TARGET_CXX) \
		$(HOST_DIR)/bin/node $(HOST_DIR)/usr/lib/node_modules/node-gyp/bin/node-gyp.js build \
			--nodedir=$(HOST_DIR)/usr \
			--jobs=$(PARALLEL_JOBS) \
			--directory=$(@D) \
			|| (echo "node-gyp build failed"; exit 1); \
		[ -f $(@D)/build/Release/logger.node ] || (echo "logger.node not generated"; exit 1); \
	fi

	@echo "Finished LOGGER_BUILD_CMDS"
endef

define LOGGER_INSTALL_STAGING_CMDS
	$(INSTALL) -d -m 755 $(STAGING_DIR)/usr/include/logger
	$(INSTALL) -D -m 644 $(@D)/logger.h $(STAGING_DIR)/usr/include/logger/logger.h \
		|| (echo "Failed to install logger.h to staging"; exit 1)
	$(INSTALL) -D -m 755 $(@D)/liblogger.so $(STAGING_DIR)/usr/lib/liblogger.so \
		|| (echo "Failed to install liblogger.so to staging"; exit 1)
endef

define LOGGER_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 755 $(TARGET_DIR)/usr/lib64
	$(INSTALL) -d -m 755 $(TARGET_DIR)/usr/include/logger
	$(INSTALL) -D -m 755 $(@D)/liblogger.so $(TARGET_DIR)/usr/lib/liblogger.so \
		|| (echo "Failed to install liblogger.so to target"; exit 1)
	$(INSTALL) -D -m 755 $(@D)/liblogger.so $(TARGET_DIR)/usr/lib64/liblogger.so \
		|| (echo "Failed to install liblogger.so to target"; exit 1)
	$(INSTALL) -D -m 644 $(@D)/logger.h $(TARGET_DIR)/usr/include/logger/logger.h \
		|| (echo "Failed to install logger.h to target"; exit 1)
	if [ "$(BR2_PACKAGE_LOGGER_NODEJS)" = "y" ]; then \
		$(INSTALL) -d -m 755 $(TARGET_DIR)/usr/lib/node_modules/logger && \
		$(INSTALL) -D -m 755 $(@D)/build/Release/logger.node $(TARGET_DIR)/usr/lib/node_modules/logger/logger.node || \
		(echo "Failed to install logger.node to target"; exit 1); \
	fi	
endef

$(eval $(generic-package))