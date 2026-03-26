debian/linux-image-$(krel).stamp: vmlinux
	@dh_prep -p$(pkgname)
	image="$$($(KMAKE) -s image_name)"
	case "$${image##*/}" in
	bzImage|vmlinuz.efi|Image.*) kfile=/boot/vmlinuz-$(krel); compress=-Znone;;
	*)                           kfile=/boot/vmlinux-$(krel); compress=;;
	esac
	install -dm755 "debian/$(pkgname)$${kfile%/*}"
	install -m600 "$$image" "debian/$(pkgname)$$kfile"
	for i in debian/templates/image.*; do
	  sed -e 's|@krel@|$(krel)|g' -e "s|@kfile@|$$kfile|g" "$$i" > "debian/$(pkgname).$${i##*.}"
	done
	echo 'interest linux-update-$(krel)' | install -m644 /dev/stdin 'debian/$(pkgname).triggers'
	# set Provides from .config
	provides=
	if grep -q ^CONFIG_FUSE_FS=y .config; then
	  provides="$$provides, fuse-module"
	fi
	if grep -q ^CONFIG_WIREGUARD=y .config; then
	  provides="$$provides, wireguard-modules (= 1.0.0)"
	fi
	echo "misc:Provides=$${provides#, }" > debian/$(pkgname).substvars
	dh_installchangelogs -p$(pkgname)
	dh_installdocs -p$(pkgname)
	dh_compress -p$(pkgname)
	dh_fixperms -p$(pkgname) -X"$$kfile"
	dh_installdeb -p$(pkgname)
	#dh_installdebconf -p$(pkgname)
	dh_md5sums -p$(pkgname)
	$(lock) dh_gencontrol -p$(pkgname)
	dh_builddeb -p$(pkgname) -- $$compress
	touch $@
