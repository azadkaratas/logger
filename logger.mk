################################################################################
#
# logger
#
################################################################################

LOGGER_VERSION = 1.0
LOGGER_SITE = $(LOGGER_PKGDIR)
LOGGER_SITE_METHOD = local
LOGGER_LICENSE_FILES = LICENSE
LOGGER_INSTALL_STAGING = YES
LOGGER_INSTALL_TARGET = YES

# Define compiler and linker flags
LOGGER_CFLAGS = $(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -fPIC
LOGGER_LDFLAGS = $(TARGET_LDFLAGS) -shared

define LOGGER_BUILD_CMDS
	$(TARGET_CC) $(LOGGER_CFLAGS) -c $(@D)/logger.c -o $(@D)/logger.o
	$(TARGET_CC) $(LOGGER_LDFLAGS) $(@D)/logger.o -o $(@D)/liblogger.so
endef

define LOGGER_INSTALL_STAGING_CMDS
	$(INSTALL) -d -m 0755 $(STAGING_DIR)/usr/lib64
	$(INSTALL) -d -m 0755 $(STAGING_DIR)/usr/include/logger
	$(INSTALL) -D -m 0755 $(@D)/liblogger.so $(STAGING_DIR)/usr/lib64/liblogger.so
	$(INSTALL) -D -m 0644 $(@D)/logger.h $(STAGING_DIR)/usr/include/logger/logger.h
endef

define LOGGER_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/lib64
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/include/logger
	$(INSTALL) -D -m 0755 $(@D)/liblogger.so $(TARGET_DIR)/usr/lib64/liblogger.so
	$(INSTALL) -D -m 0644 $(@D)/logger.h $(TARGET_DIR)/usr/include/logger/logger.h
endef

$(eval $(generic-package))