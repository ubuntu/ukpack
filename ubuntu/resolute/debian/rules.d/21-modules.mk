debian/linux-modules-$(krel).stamp: vmlinux
	@dh_prep -p$(pkgname)
	image="$$($(KMAKE) -s image_name)"
	case "$${image##*/}" in
	bzImage|vmlinuz.efi|Image.*) kfile=vmlinuz;;
	*)                           kfile=vmlinux;;
	esac
	targets='modules_install $(vdso-install)'
	if grep -q ^CONFIG_OF= .config; then
	  targets="$$targets dtbs_install"
	  # this directory is automatically created by make dtbs_install,
	  # but we need to narrow the window for a race in rust /usr/bin/install
	  install -dm755 debian/$(pkgname)/usr/lib/firmware/$(krel)/device-tree
	fi
	ZSTD_CLEVEL=19 \
	$(KMAKE) $(if $(install-mod-strip),INSTALL_MOD_STRIP='$(install-mod-strip)' )\
	  INSTALL_MOD_PATH=debian/$(pkgname)/usr \
	  INSTALL_DTBS_PATH=debian/$(pkgname)/usr/lib/firmware/$(krel)/device-tree \
	  $$targets
	rm -f debian/$(pkgname)/usr/lib/modules/$(krel)/build
	install -dm755 debian/$(pkgname)/boot
	install -m644 .config debian/$(pkgname)/boot/config-$(krel)
	install -m600 System.map debian/$(pkgname)/boot/System.map-$(krel)
	if [ -n '$(ukify)']; then
	  install -m644 "$$image" "debian/$(pkgname)/usr/lib/modules/$(krel)/$$kfile"
	fi
	if [ -n '$(force-compress-modules)' ]; then
	  find debian/$(pkgname) -name '*.ko' -print0 | \
	    xargs -0 -r -n 1$(if $(JOBS), -P $(JOBS)) $(force-compress-modules)
	fi
	install -dm755 debian/$(pkgname)/usr/lib/linux/triggers
	for i in debian/templates/modules.*; do
	  sed -e 's|@krel@|$(krel)|g' -e "s|@kfile@|/boot/$${kfile}-$(krel)|g" "$$i" > "debian/$(pkgname).$${i##*.}"
	done
	# set Provides from .config
	provides=
	if grep -q ^CONFIG_FUSE_FS=m .config; then
	  provides="$$provides, fuse-module"
	fi
	if grep -q ^CONFIG_WIREGUARD=m .config; then
	  provides="$$provides, wireguard-modules (= 1.0.0)"
	fi
	echo "misc:Provides=$${provides#, }" > debian/$(pkgname).substvars
	dh_installchangelogs -p$(pkgname)
	dh_installdocs -p$(pkgname)
	dh_compress -p$(pkgname)
	dh_fixperms -p$(pkgname) -X/boot/System.map-$(krel)
	dh_installdeb -p$(pkgname)
	dh_md5sums -p$(pkgname)
	$(lock) dh_gencontrol -p$(pkgname)
	# disable package compression if all modules are compressed
	if find debian/$(pkgname) -name '*.ko' -exec false '{}' +; then
	  compress=-Znone
	fi
	dh_builddeb -p$(pkgname) -- $$compress
	touch $@
