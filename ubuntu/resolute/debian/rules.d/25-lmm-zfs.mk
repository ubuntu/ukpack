debian/linux-main-modules-zfs-$(krel).stamp: build-lmm-zfs
	@dh_prep -p$(pkgname)
	install -dm755 debian/$(pkgname)/usr/lib/modules/$(krel)/kernel/zfs
	cat > dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module/modules.order <<EOF
	spl.o
	zfs.o
	EOF
	ZSTD_CLEVEL=19 \
	$(KMAKE) $(if $(install-mod-strip),INSTALL_MOD_STRIP='$(install-mod-strip)' )\
	  DEPMOD=true \
	  INSTALL_MOD_PATH=$(abspath debian)/$(pkgname)/usr \
	  INSTALL_MOD_DIR=kernel/zfs \
	  M=$(abspath dkms)/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module \
	  modules_install
	if [ -n '$(force-compress-modules)' ]; then
	  find debian/$(pkgname) -name '*.ko' -print0 | \
	    xargs -0 -r -n 1$(if $(JOBS), -P $(JOBS)) $(force-compress-modules)
	fi
	dh_installchangelogs -p$(pkgname)
	dh_installdocs -p$(pkgname)
	dh_compress -p$(pkgname)
	dh_fixperms -p$(pkgname)
	dh_installdeb -p$(pkgname)
	dh_md5sums -p$(pkgname)
	$(lock) dh_gencontrol -p$(pkgname)
	dh_builddeb -p$(pkgname)
	touch $@
