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

# usbip
tools/usb/usbip/configure:
	@cd tools/usb/usbip
	./autogen.sh

tools/usb/usbip/Makefile: tools/usb/usbip/configure
	@cd tools/usb/usbip
	./configure$(if $(CC), CC=$(CC)) \
	  --prefix=/usr \
	  --with-gnu-ld

tools/usb/usbip/src/usbip: tools/usb/usbip/Makefile
	@$(KMAKE) -C tools/usb/usbip

.PHONY: build-usbip
build-usbip: tools/usb/usbip/src/usbip

# acpidbg
tools/power/acpi/acpidbg:
	@$(KMAKE) -C tools/power/acpi DEBUG=false

.PHONY: build-acpidbg
build-acpidbg: tools/power/acpi/acpidbg

# rtla
tools/tracing/rtla/rtla-static:
	@$(KMAKE) -C tools/tracing/rtla LD=ld static

.PHONY: build-rtla
build-rtla: tools/tracing/rtla/rtla-static

# cpupower
tools/power/cpupower/cpupower:
	@$(KMAKE) -C tools/power/cpupower DEBUG=false STATIC=true CPUFREQ_BENCH=false

.PHONY: build-cpupower
build-cpupower: tools/power/cpupower/cpupower

# perf
tools/perf/perf:
	@$(KMAKE) -C tools/perf -f Makefile.perf prefix=/usr HAVE_CPLUS_DEMANGLE_SUPPORT=1 NO_LIBPERL=1 WERROR=0

.PHONY: build-perf
build-perf: tools/perf/perf

# bpftool
tools/bpf/bpftool/bpftool:
	@$(KMAKE) -C tools/bpf/bpftool

.PHONY: build-bpftool
build-bpftool: tools/bpf/bpftool/bpftool

# x86
tools/power/x86/x86_energy_perf_policy/x86_energy_perf_policy:
	@$(KMAKE) -C tools/power/x86/x86_energy_perf_policy

tools/power/x86/turbostat/turbostat:
	@$(KMAKE) -C tools/power/x86/turbostat

.PHONY: build-x86
build-x86: tools/power/x86/x86_energy_perf_policy/x86_energy_perf_policy tools/power/x86/turbostat/turbostat

dkms/:
	@mkdir dkms

# lmm-zfs
ifneq ($(filter linux-main-modules-zfs-%,$(packages-arch)),)
dkms-zfs-version := $(shell dkms status zfs | sed -ne '1s|^zfs/\([1-9][.0-9]*\).*|\1|p')
dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module/zfs.ko: vmlinux | dkms/
	@ret=0
	$(if $(ARCH),KERNEL_ARCH=$(ARCH) )\
	$(if $(CROSS_COMPILE),CROSS_COMPILE=$(CROSS_COMPILE) )\
	ZFS_DKMS_DISABLE_STRIP=y \
	dkms build --verbose \
	  --dkmstree $(abspath dkms) \
	  --kernelsourcedir $(abspath .) \
	  zfs/$(dkms-zfs-version) -k $(krel)/$(karch) || ret=$$?
	if [ $$ret -ne 0 ]; then
	  cat dkms/zfs/$(dkms-zfs-version)/build/make.log
	  exit $$ret
	fi
	cat dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/log/*
	for i in spl zfs; do
	  [ ! -f dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module/$${i}.ko.zst ] || \
	    zstd -d dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module/$${i}.ko.zst
	  [ ! -f dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module/$${i}.ko.xz ] || \
	    xz -d dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module/$${i}.ko.xz
	  [ ! -f dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module/$${i}.ko.gz ] || \
	    gzip -d dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module/$${i}.ko.gz
	done

.PHONY: build-lmm-zfs
build-lmm-zfs: dkms/zfs/$(dkms-zfs-version)/$(krel)/$(karch)/module/zfs.ko
endif
