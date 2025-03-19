debian/linux-headers-$(krel).stamp: vmlinux
	@dh_prep -p$(pkgname)
	dest='debian/$(pkgname)/usr/src/$(pkgname)'
	install -dm755 "$$dest"
	set +x
	echo '+ Installing Kconfig files'
	find . \
	  -path './.git' -prune -o \
	  -path './Documentation' -prune -o \
	  -path './debian' -prune -o \
	  -path './scripts' -prune -o \
	  -name 'Kconfig*' -print | \
	while read -r file; do
	  install -dm755 "$$dest/$${file%/*}"
	  install -pm644 "$$file" "$$dest/$$file"
	done
	set -x
	install -pm644 .config "$$dest/.config"
	install -pm644 Module.symvers "$$dest/Module.symvers"
	install -pm644 Makefile "$$dest/Makefile"
	install -pm644 kernel/Makefile "$$dest/kernel/Makefile"
	install -pm644 arch/$(karch)/Makefile "$$dest/arch/$(karch)/Makefile"
	cp -rP --preserve=mode,links,timestamps include "$$dest/"
	cp -rP --preserve=mode,links,timestamps arch/$(karch)/include "$$dest/arch/$(karch)/"
	cp -rP --preserve=mode,links,timestamps scripts "$$dest/"
	find "$$dest/scripts" -name '*.o' -delete -o -name '*.cmd' -delete
	if [ -x tools/objtool/objtool ]; then
	  install -dm755 "$$dest/tools/objtool"
	  install -pm755 tools/objtool/objtool "$$dest/tools/objtool/objtool"
	fi
	echo "#define UTS_UBUNTU_RELEASE_ABI $(abi-number)" >> \
	  "$$dest/include/generated/utsrelease.h"
	if [ '$(karch)' = 'powerpc' ]; then
	  install -dm755 "$$dest/arch/powerpc/lib"
	  cp -Pl --preserve=mode,links,timestamps arch/powerpc/lib/*.o "$$dest/arch/powerpc/lib"
	fi
	install -dm755 debian/$(pkgname)/usr/lib/modules/$(krel)
	ln -s /usr/src/$(pkgname) debian/$(pkgname)/usr/lib/modules/$(krel)/build
	for i in debian/templates/headers.*; do
	  sed -e 's|@krel@|$(krel)|g' -e "s|@kfile@|$$kfile|g" "$$i" > "debian/$(pkgname).$${i##*.}"
	done
	dh_installchangelogs -p$(pkgname)
	dh_installdocs -p$(pkgname)
	dh_compress -p$(pkgname)
	dh_fixperms -p$(pkgname) -X/boot/System.map-$(krel)
	dh_installdeb -p$(pkgname)
	dh_md5sums -p$(pkgname)
	$(lock) dh_gencontrol -p$(pkgname)
	dh_builddeb -p$(pkgname)
	touch $@
