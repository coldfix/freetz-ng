GCC_KERNEL_VERSION:=$(KERNEL_TOOLCHAIN_GCC_VERSION)
GCC_KERNEL_MAJOR_VERSION:=$(call GET_MAJOR_VERSION,$(GCC_KERNEL_VERSION),$(if $(or $(FREETZ_KERNEL_GCC_3_4),$(FREETZ_KERNEL_GCC_4_6),$(FREETZ_KERNEL_GCC_4_7),$(FREETZ_KERNEL_GCC_4_8)),2,1))
GCC_KERNEL_SOURCE:=gcc-$(GCC_KERNEL_VERSION).tar.$(if $(or $(FREETZ_KERNEL_GCC_3_4),$(FREETZ_KERNEL_GCC_4_6),$(FREETZ_KERNEL_GCC_4_7),$(FREETZ_KERNEL_GCC_4_8)),bz2,xz)
GCC_KERNEL_SITE:=@GNU/gcc/gcc-$(GCC_KERNEL_VERSION)
GCC_KERNEL_DIR:=$(KERNEL_TOOLCHAIN_DIR)/gcc-$(GCC_KERNEL_VERSION)
GCC_KERNEL_MAKE_DIR:=$(TOOLCHAIN_DIR)/make/kernel/gcc
GCC_KERNEL_BUILD_DIR:=$(KERNEL_TOOLCHAIN_DIR)/gcc-$(GCC_KERNEL_VERSION)-build

GCC_KERNEL_HASH_3.4.6 := 7791a601878b765669022b8b3409fba33cc72f9e39340fec8af6d0e6f72dec39
GCC_KERNEL_HASH_4.6.4 := 35af16afa0b67af9b8eb15cafb76d2bc5f568540552522f5dc2c88dd45d977e8
GCC_KERNEL_HASH_4.7.4 := 92e61c6dc3a0a449e62d72a38185fda550168a86702dea07125ebd3ec3996282
GCC_KERNEL_HASH_4.8.5 := 22fb1e7e0f68a63cee631d85b20461d1ea6bda162f03096350e38c8d427ecf23
GCC_KERNEL_HASH_5.5.0 := 530cea139d82fe542b358961130c69cfde8b3d14556370b65823d2f91f0ced87
GCC_KERNEL_HASH_8.3.0 := 64baadfe6cc0f4947a84cb12d7f0dfaf45bb58b7e92461639596c21e02d97d2c
GCC_KERNEL_HASH       := $(GCC_KERNEL_HASH_$(GCC_KERNEL_VERSION))

GCC_KERNEL_ECHO_TYPE:=KTC
GCC_KERNEL_ECHO_MAKE:=gcc


GCC_KERNEL_INITIAL_PREREQ=

ifndef KERNEL_TOOLCHAIN_NO_MPFR
GCC_KERNEL_DECIMAL_FLOAT  := --disable-decimal-float

GCC_KERNEL_INITIAL_PREREQ += $(GMP_HOST_BINARY) $(MPFR_HOST_BINARY) $(MPC_HOST_BINARY)
GCC_KERNEL_WITH_HOST_GMP   = --with-gmp=$(GMP_HOST_DESTDIR)
GCC_KERNEL_WITH_HOST_MPFR  = --with-mpfr=$(MPFR_HOST_DESTDIR)
GCC_KERNEL_WITH_HOST_MPC   = --with-mpc=$(MPC_HOST_DESTDIR)
endif

# --with-isl is available since gcc-4.8.x, exclude all versions before
ifneq ($(or $(FREETZ_KERNEL_GCC_3_4),$(FREETZ_KERNEL_GCC_4_6),$(FREETZ_KERNEL_GCC_4_7)),y)
GCC_KERNEL_WITH_HOST_ISL   = --with-isl=no
endif

GCC_KERNEL_EXTRA_MAKE_OPTIONS := MAKEINFO=true


gcc-kernel-source: $(DL_DIR)/$(GCC_KERNEL_SOURCE)
$(DL_DIR)/$(GCC_KERNEL_SOURCE): | $(DL_DIR)
	@$(call _ECHO,downloading,$(GCC_KERNEL_ECHO_TYPE),$(GCC_KERNEL_ECHO_MAKE))
	$(DL_TOOL) $(DL_DIR) $(GCC_KERNEL_SOURCE) $(GCC_KERNEL_SITE) $(GCC_KERNEL_HASH) $(SILENT)

gcc-kernel-unpacked: $(GCC_KERNEL_DIR)/.unpacked
$(GCC_KERNEL_DIR)/.unpacked: $(DL_DIR)/$(GCC_KERNEL_SOURCE) | $(KERNEL_TOOLCHAIN_DIR) $(UNPACK_TARBALL_PREREQUISITES)
	@$(call _ECHO,unpacking,$(GCC_KERNEL_ECHO_TYPE),$(GCC_KERNEL_ECHO_MAKE))
	$(RM) -r $(GCC_KERNEL_DIR)
	$(call UNPACK_TARBALL,$(DL_DIR)/$(GCC_KERNEL_SOURCE),$(KERNEL_TOOLCHAIN_DIR))
	$(call APPLY_PATCHES,$(GCC_KERNEL_MAKE_DIR)/$(GCC_KERNEL_MAJOR_VERSION),$(GCC_KERNEL_DIR))
	touch $@

$(GCC_KERNEL_BUILD_DIR)/.configured: $(GCC_KERNEL_DIR)/.unpacked $(GCC_KERNEL_INITIAL_PREREQ) | binutils-kernel
	@$(call _ECHO,configuring,$(GCC_KERNEL_ECHO_TYPE),$(GCC_KERNEL_ECHO_MAKE))
	mkdir -p $(GCC_KERNEL_BUILD_DIR)
	(cd $(GCC_KERNEL_BUILD_DIR); PATH=$(KERNEL_TOOLCHAIN_PATH) \
		CC="$(TOOLCHAIN_HOSTCC)" \
		CFLAGS="$(TOOLCHAIN_HOST_CFLAGS)" \
		CXXFLAGS="$(TOOLCHAIN_HOST_CFLAGS)" \
		$(GCC_KERNEL_DIR)/configure \
		--enable-option-checking \
		--prefix=$(KERNEL_TOOLCHAIN_STAGING_DIR) \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_HOST_NAME) \
		--target=$(REAL_GNU_KERNEL_NAME) \
		--enable-languages=c \
		--disable-shared \
		--with-newlib \
		--disable-libssp \
		--with-gnu-as \
		--with-gnu-ld \
		--without-headers \
		--disable-threads \
		--disable-multilib \
		$(strip $(GCC_COMMON_CONFIGURE_OPTIONS_HW_CAPABILITIES)) \
		$(GCC_KERNEL_DECIMAL_FLOAT) \
		$(GCC_KERNEL_WITH_HOST_GMP) \
		$(GCC_KERNEL_WITH_HOST_MPFR) \
		$(GCC_KERNEL_WITH_HOST_MPC) \
		$(GCC_KERNEL_WITH_HOST_ISL) \
		--disable-nls \
		$(SILENT) \
	);
	touch $@

$(GCC_KERNEL_BUILD_DIR)/.compiled: $(GCC_KERNEL_BUILD_DIR)/.configured
	@$(call _ECHO,building,$(GCC_KERNEL_ECHO_TYPE),$(GCC_KERNEL_ECHO_MAKE))
	PATH=$(KERNEL_TOOLCHAIN_PATH) $(MAKE) $(GCC_KERNEL_EXTRA_MAKE_OPTIONS) -C $(GCC_KERNEL_BUILD_DIR) all-gcc $(SILENT)
	touch $@

$(KERNEL_CROSS_COMPILER): $(GCC_KERNEL_BUILD_DIR)/.compiled
	@$(call _ECHO,installing,$(GCC_KERNEL_ECHO_TYPE),$(GCC_KERNEL_ECHO_MAKE))
	PATH=$(KERNEL_TOOLCHAIN_PATH) $(MAKE1) $(GCC_KERNEL_EXTRA_MAKE_OPTIONS) -C $(GCC_KERNEL_BUILD_DIR) install-gcc $(SILENT)
	$(call GCC_INSTALL_COMMON,$(KERNEL_TOOLCHAIN_STAGING_DIR),$(GCC_KERNEL_MAJOR_VERSION),$(REAL_GNU_KERNEL_NAME),$(HOST_STRIP))
	$(call REMOVE_DOC_NLS_DIRS,$(KERNEL_TOOLCHAIN_STAGING_DIR))

gcc-kernel: binutils-kernel $(KERNEL_CROSS_COMPILER)


gcc-kernel-uninstall:
	$(RM) $(call TOOLCHAIN_BINARIES_LIST,$(KERNEL_TOOLCHAIN_STAGING_DIR),$(GCC_BINARIES_BIN),$(REAL_GNU_KERNEL_NAME))
	$(RM) -r $(KERNEL_TOOLCHAIN_STAGING_DIR)/{lib,libexec}/gcc

gcc-kernel-clean: gcc-kernel-uninstall
	$(RM) -r $(GCC_KERNEL_BUILD_DIR)

gcc-kernel-dirclean: gcc-kernel-clean
	$(RM) -r $(GCC_KERNEL_DIR)

gcc-kernel-distclean: gcc-kernel-dirclean


.PHONY: gcc-kernel gcc-kernel-source gcc-kernel-unpacked
.PHONY: gcc-kernel-uninstall gcc-kernel-clean gcc-kernel-dirclean gcc-kernel-distclean

