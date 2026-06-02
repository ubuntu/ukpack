debian/linux-image-$(flavour).stamp:
	@dh_prep -p$(pkgname)
	if $(if $(filter linux-main-modules-zfs-%,$(packages-arch)),true,false); then
	  echo 'misc:Depends=linux-main-modules-zfs-$(krel)' > debian/$(pkgname).substvars
	fi
	dh_installchangelogs -p$(pkgname)
	dh_installdocs -p$(pkgname)
	dh_compress -p$(pkgname)
	dh_fixperms -p$(pkgname)
	dh_md5sums -p$(pkgname)
	$(lock) dh_gencontrol -p$(pkgname)
	dh_builddeb -p$(pkgname)
	touch $@
