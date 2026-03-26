debian/linux-tools-$(krel).stamp: $(tools:%=build-%)
	@dh_prep -p$(pkgname)
	install -dm755 debian/$(pkgname)/usr/lib/linux-tools/$(krel)
	[ ! -x tools/usb/usbip/src/usbip ] || \
	  install -m755 tools/usb/usbip/src/usbip \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/usbip
	[ ! -x tools/usb/usbip/src/usbip ] || \
	  install -m755 tools/usb/usbip/src/usbipd \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/usbipd
	[ ! -x tools/power/acpi/acpidbg ] || \
	  install -m755 tools/power/acpi/acpidbg \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/acpidbg
	[ ! -x tools/tracing/rtla/rtla-static ] || \
	  install -m755 tools/tracing/rtla/rtla-static \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/rtla
	[ ! -x tools/power/cpupower/cpupower ] || \
	  install -m755 tools/power/cpupower/cpupower \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/cpupower
	[ ! -x tools/perf/perf ] || \
	  install -m755 tools/perf/perf \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/perf
	[ ! -x tools/perf/libperf-jvmti.so ] || \
	  install -m755 tools/perf/libperf-jvmti.so \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/libperf-jvmti.so
	for i in tools/perf/python/perf.cpython-*.so; do
	  if [ -x "$$i" ]; then
	    install -dm755 debian/$(pkgname)/usr/lib/linux-tools/$(krel)/lib
	    install -m755 "$$i" debian/$(pkgname)/usr/lib/linux-tools/$(krel)/lib/
	    break
	  fi
	done
	[ ! -x tools/bpf/bpftool/bpftool ] || \
	  install -m755 tools/bpf/bpftool/bpftool \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/bpftool
	[ ! -x tools/power/x86/x86_energy_perf_policy/x86_energy_perf_policy ] || \
	  install -m755 tools/power/x86/x86_energy_perf_policy/x86_energy_perf_policy \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/x86_energy_perf_policy
	[ ! -x tools/power/x86/turbostat/turbostat ] || \
	  install -m755 tools/power/x86/turbostat/turbostat \
	                debian/$(pkgname)/usr/lib/linux-tools/$(krel)/turbostat
	dh_installchangelogs -p$(pkgname)
	dh_installdocs -p$(pkgname)
	dh_compress -p$(pkgname)
	dh_fixperms -p$(pkgname)
	dh_shlibdeps -p$(pkgname)
	dh_installdeb -p$(pkgname)
	dh_md5sums -p$(pkgname)
	$(lock) dh_gencontrol -p$(pkgname)
	dh_builddeb -p$(pkgname)
	touch $@
