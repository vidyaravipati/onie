#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of Debian busybox
#

UCLIBC_VERSION		= 0.9.32.1
UCLIBC_TARBALL		= uClibc-$(UCLIBC_VERSION).tar.xz
UCLIBC_TARBALL_SIGN	= $(UCLIBC_TARBALL).sign
UCLIBC_TARBALL_URLS	= http://www.uclibc.org/downloads
UCLIBC_BUILD_DIR	= $(MBUILDDIR)/uclibc
UCLIBC_DIR		= $(UCLIBC_BUILD_DIR)/uClibc-$(UCLIBC_VERSION)
UCLIBC_CONFIG		= conf/uclibc-$(ARCH).config
UCLIBC_DEV_SYSROOT	= $(UCLIBC_BUILD_DIR)/uclibc-dev-sysroot

UCLIBC_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/uclibc-download
UCLIBC_SOURCE_STAMP	= $(STAMPDIR)/uclibc-source
UCLIBC_BUILD_STAMP	= $(STAMPDIR)/uclibc-build
UCLIBC_INSTALL_STAMP	= $(STAMPDIR)/uclibc-install
UCLIBC_STAMP		= $(UCLIBC_DOWNLOAD_STAMP) \
			  $(UCLIBC_SOURCE_STAMP) \
			  $(UCLIBC_BUILD_STAMP) \
			  $(UCLIBC_INSTALL_STAMP)

PHONY += uclibc uclibc-download uclibc-source uclibc-build \
	 uclibc-install uclibc-clean uclibc-download-clean

uclibc: $(UCLIBC_STAMP)

DOWNLOAD += $(UCLIBC_DOWNLOAD_STAMP)
uclibc-download: $(UCLIBC_DOWNLOAD_STAMP)
$(UCLIBC_DOWNLOAD_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream uClibc ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UCLIBC_TARBALL) $(UCLIBC_TARBALL_URLS)
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UCLIBC_TARBALL_SIGN) $(UCLIBC_TARBALL_URLS)
	$(Q) cd $(DOWNLOADDIR) && grep SHA256 $(UCLIBC_TARBALL_SIGN) | sed -e 's/^SHA256: //' | sha256sum -c -
	$(Q) touch $@

SOURCE += $(UCLIBC_SOURCE_STAMP)
uclibc-source: $(UCLIBC_SOURCE_STAMP)
$(UCLIBC_SOURCE_STAMP): $(UCLIBC_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream uClibc ===="
	$(Q) $(SCRIPTDIR)/extract-package $(UCLIBC_BUILD_DIR) $(DOWNLOADDIR)/$(UCLIBC_TARBALL)
	$(Q) touch $@

$(UCLIBC_DIR)/.config: $(UCLIBC_CONFIG) $(UCLIBC_SOURCE_STAMP)
	$(Q) echo "==== Copying $(UCLIBC_CONFIG) to $(UCLIBC_DIR)/.config ===="
	$(Q) cp -v $< $@

uclibc-config: $(UCLIBC_DIR)/.config
	PATH='$(CROSSBIN):$(PATH)' \
		$(MAKE) -C $(UCLIBC_DIR) CROSS=$(CROSSPREFIX) menuconfig

UCLIBC_VERBOSE = 
ifneq ($(V),0)
  UCLIBC_VERBOSE = V=2
endif
uclibc-build: $(UCLIBC_BUILD_STAMP)
$(UCLIBC_BUILD_STAMP): $(UCLIBC_DIR)/.config $(KERNEL_HEADER_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building uclibc-$(UCLIBC_VERSION) ===="
	PATH='$(CROSSBIN):$(PATH)' 		\
	    $(MAKE) -C $(UCLIBC_DIR) $(UCLIBC_VERBOSE) \
		EXTRA_CFLAGS=-Wl,--hash-style=sysv \
		KERNEL_HEADERS=$(KERNEL_HEADERS) \
		CROSS=$(CROSSPREFIX)
	$(Q) touch $@

uclibc-install: $(UCLIBC_INSTALL_STAMP)
$(UCLIBC_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(UCLIBC_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing runtime uclibc in $(SYSROOTDIR) ===="
	$(Q) sudo PATH='$(CROSSBIN):$(PATH)'	\
		$(MAKE) -C $(UCLIBC_DIR) $(UCLIBC_VERBOSE) \
		EXTRA_CFLAGS=-Wl,--hash-style=sysv \
		KERNEL_HEADERS=$(KERNEL_HEADERS)  \
		CROSS=$(CROSSPREFIX)	\
		PREFIX=$(SYSROOTDIR) install_runtime install_utils
	$(Q) sudo $(CROSSBIN)/$(CROSSPREFIX)strip $(SYSROOTDIR)/{usr/bin/getconf,usr/bin/ldd,sbin/ldconfig} # fixup for unstripped binaries
	$(Q) sudo ln -fs ld-uClibc.so.0 $(SYSROOTDIR)/lib/ld.so.1 # fixup for ldd, getconf and ldconfig
	$(Q) echo "==== Installing development uclibc in $(UCLIBC_DEV_SYSROOT) ===="
	$(Q) sudo PATH='$(CROSSBIN):$(PATH)' 	\
		$(MAKE) -C $(UCLIBC_DIR) $(UCLIBC_VERBOSE) \
		EXTRA_CFLAGS=-Wl,--hash-style=sysv \
		KERNEL_HEADERS=$(KERNEL_HEADERS) \
		CROSS=$(CROSSPREFIX)	\
		PREFIX=$(UCLIBC_DEV_SYSROOT) install_dev
	$(Q) [ -d $(CROSSCOMPILER_LIBS) ] || \
		(echo "Unable to find cross compiler libraries in $(CROSSCOMPILER_LIBS)" && \
		exit 1)
	$(Q) sudo ln -fs $(CROSSCOMPILER_LIBS) $(UCLIBC_DEV_SYSROOT)/usr/lib/
	$(Q) touch $@

CLEAN += uclibc-clean
uclibc-clean:
	$(Q) sudo rm -rf $(UCLIBC_DEV_SYSROOT)
	$(Q) rm -rf $(UCLIBC_BUILD_DIR)
	$(Q) rm -f $(UCLIBC_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

CLEAN_DOWNLOAD += uclibc-download-clean
uclibc-download-clean:
	$(Q) rm -f $(UCLIBC_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(UCLIBC_TARBALL_SIGN) \
		   $(DOWNLOADDIR)/$(UCLIBC_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
