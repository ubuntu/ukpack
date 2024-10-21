.config:
	@if [ -f debian/$(DEB_HOST_ARCH).config ]; then
	  cp debian/$(DEB_HOST_ARCH).config .config
	  $(KMAKE) syncconfig
	  diff -Naur debian/$(DEB_HOST_ARCH).config .config
	elif [ -f debian/$(DEB_HOST_ARCH)_defconfig ]; then
	  cp -f debian/$(DEB_HOST_ARCH)_defconfig arch/$(karch)/configs/ubuntu_defconfig
	  $(KMAKE) ubuntu_defconfig
	else
	  $(KMAKE) '$(config)'
	fi

vmlinux: .config
	@$(KMAKE)
