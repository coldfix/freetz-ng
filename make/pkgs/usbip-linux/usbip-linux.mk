$(call PKG_INIT_BIN, 0.1)

# $(PKG)_SOURCE:=$(call qstrip,$(FREETZ_DL_KERNEL_VANILLA_SOURCE))
# $(PKG)_HASH:=$(call qstrip,$(FREETZ_DL_KERNEL_VANILLA_HASH))
# $(PKG)_SITE:=@KERNEL/linux/kernel/v$(call qstrip,$(FREETZ_KERNEL_VANILLA_DLDIR))

$(PKG)_LINUX_CATEGORY:=Unstable

$(PKG)_BINARIES            := usbip usbipd # usbip_bind_driver
$(PKG)_BINARIES_BUILD_DIR  := $($(PKG)_BINARIES:%=$($(PKG)_DIR)/src/%)
$(PKG)_BINARIES_TARGET_DIR := $($(PKG)_BINARIES:%=$($(PKG)_DEST_DIR)/usr/sbin/%)

$(PKG)_DEPENDS_ON += kernel sysfsutils # glib2

$(PKG)_PATCH_PRE_CMDS = cp -r $(FREETZ_BASE_DIR)/$(KERNEL_SOURCE_DIR)/tools/usb/usbip/* ./;
$(PKG)_PATCH_PRE_CMDS += cp $(FREETZ_BASE_DIR)/make/pkgs/usbip-linux/libudev.h src/;
$(PKG)_PATCH_PRE_CMDS += cp $(FREETZ_BASE_DIR)/make/pkgs/usbip-linux/libudev.h libsrc/;

# TODO: only available *after* first image creation:
$(PKG)_CONFIGURE_PRE_CMDS += ln -sT libudev.so.1 $(FREETZ_BASE_DIR)/build/original/filesystem/lib/libudev.so;
$(PKG)_CONFIGURE_PRE_CMDS += ./autogen.sh;
$(PKG)_CONFIGURE_PRE_CMDS += $(call PKG_PREVENT_RPATH_HARDCODING,./configure)

$(PKG)_CONFIGURE_OPTIONS += --with-usbids-dir=/usr/share/
$(PKG)_CONFIGURE_OPTIONS += --with-tcp-wrappers=no	# TODO = yes?
$(PKG)_CONFIGURE_OPTIONS += --enable-shared=no
$(PKG)_CONFIGURE_OPTIONS += LDFLAGS=-L$(FREETZ_BASE_DIR)/build/original/filesystem/lib

# $(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_CONFIGURE)

$($(PKG)_BINARIES_BUILD_DIR): $($(PKG)_DIR)/.configured
	$(SUBMAKE) -C $(USBIP_LINUX_DIR)

$($(PKG)_BINARIES_TARGET_DIR): $($(PKG)_DEST_DIR)/usr/sbin/%: $($(PKG)_DIR)/src/%
	$(INSTALL_BINARY_STRIP)

$(pkg):

$(pkg)-precompiled: $($(PKG)_BINARIES_TARGET_DIR)

$(pkg)-clean:
	-$(SUBMAKE) -C $(USBIP_LINUX_DIR) clean
	$(RM) $(USBIP_LINUX_DIR)/.configured

$(pkg)-uninstall:
	$(RM) $(USBIP_LINUX_BINARIES_TARGET_DIR)

$(PKG_FINISH)
