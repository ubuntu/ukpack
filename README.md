# ukpack

## What is this?

This is a tool to create an [Ubuntu] kernel source package so you can build any [Linux
git repository][repo] in a [PPA] and produce packages that look like regular Ubuntu kernels.

[Ubuntu]: https://ubuntu.com/
[repo]: https://git.kernel.org/
[PPA]: https://launchpad.net/ubuntu/+ppas

## How?

#### Get set up

Clone this repository
```
git clone https://github.com/ubuntu/ukpack.git
```
and make sure you have the tools installed to build a Debian source package
```
apt-get install python3 git dpkg-dev devscripts
```

#### Create a changelog/metadata file

Write something like this to your `example.toml` file

```
linux-example (6.8.12-1.1) noble; urgency=medium

  * My first kernel package.

 -- Your Full Name <your@email.com>  Fri, 07 Mar 2025 16:10:55 +0100
---
# set which architectures to build this kernel for
arch = "amd64"

# which configuration to use (can be your own out-of-tree config)
config = "defconfig"

[pkg.source]
Maintainer = "Your Full Name <your@email.com>"
```

Every Debian package needs a changelog which also sets the package name, version as well as the release to build for.
For the kernel package we need a bit more data to know how to build the package.
For example which kernel configuration to use and which architecture(s) to build it for.
This is appended in [TOML] format after the `---`.
Here we can also overwrite various data included in the packages, like fx. who maintains them.

[TOML]: https://toml.io/

#### Run ukpack

```
$ cd ukpack
$ ./ukpack -t path/to/linux/repo example.toml
Creating debian directory
Downloading https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.8.12.tar.xz
- use -o/--orig to use a previous download
100.00%
Creating debian/patches/6.8.12-1.1.patch
+ git diff -U0 632428373bea7581869cb05dce40bef0d37793e3..HEAD -- :(exclude)debian/
Creating linux-example_6.8.12-1.1.debian.tar.xz
+ xz --verbose --compress --stdout
  100 %          7.636 B / 80,0 KiB = 0,093
Creating linux-example_6.8.12-1.1.dsc
+ dpkg-source --format=3.0 (custom) --target-format=3.0 (quilt) --build linux-example linux-example_6.8.12.orig.tar.xz linux-example_6.8.12-1.1.debian.tar.xz
dpkg-source: info: using source format '3.0 (custom)'
dpkg-source: info: building linux-example in linux-example_6.8.12-1.1.dsc
Creating linux-example_6.8.12-1.1_source.buildinfo
+ dpkg-genbuildinfo --build=source
Creating linux-example_6.8.12-1.1_source.changes
+ dpkg-genchanges --build=source -sa -O../linux-example_6.8.12-1.1_source.changes
dpkg-genchanges: info: including full source code in upload
Source package built successfully \o/
Sign package:    debsign linux-example_6.8.12-1.1_source.changes
Upload package:  dput <PPA> linux-example_6.8.12-1.1_source.changes
```

Now you can build your kernel package by signing and uploading it to a PPA like mentioned above.

## How-to

### Name and version your kernel

The kernel package is named from the first line of the changelog/metadata file
and must always begin with `linux-`.
The rest of the name is used to distinguish the kernel from the generic Ubuntu kernel and other series.

The version number must begin with the upstream kernel release your kernel tree is based on
followed by a dash (-) and the package version.
Usually it has the form `<upstream>-<abi>.<upload>` where

* __upstream__ The upstream kernel release your kernel tree is based on. Eg. the latest tag.
* __abi__ A rolling number to designate the version of your kernel package.
  You can have multiple versions of the same kernel installed as long as they have different upstream and/or abi numbers.
* __upload__ If an error happens when building the kernel in a PPA you will need to correct the error and upload a new version.
  However the PPA will require a newer version number, so you can bump this number to try again.
  Kernel packages with higher upload numbers will _replace_ kernel packages
  with lower upload numbers if the upstream and abi numbers are the same.

### Configure your kernel

There are 3 options to configure your kernel:

- __Use a defconfig checked into your kernel tree under `arch/<arch>/configs/`.__
  Set `config = "my_defconfig"`.
  It must end in `_defconfig`.
- __Use an out-of-tree defconfig file.__
  Set `config = "/path/to/my_defconfig"`.
  The path is relative to the changelog/metadata file, must contain a `/` and end in `_defconfig`.
- __Use an out-of-tree full configuration file.__
  Set `config = "/path/to/my.config"`.
  The path is relative to the changelog/metadata file and must not end in `_defconfig`.
  When building in the PPA it will be checked that the config is not changed by `make syncconfig`,
  so the config file must be generated with the same compiler as used in the PPA.

If you're building a kernel for multiple architectures you can overwrite the config used for a
specific architecture like this:
```toml
[amd64]
config = "./my_intel_defconfig"
[riscv64]
config = "defconfig" # just use defconfig on riscv64
```

### Build a Unified Kernel Image (UKI) with ukify

By default the kernel image is installed as a plain `vmlinuz`/`vmlinux` file, which a
bootloader has to load separately from an initrd and kernel command line.
Instead, ukpack can pack the kernel image for you into a
[Unified Kernel Image (UKI)][uki] using [`ukify`][ukify-man], the tool shipped with
[systemd] that combines a UEFI stub, the kernel image, and optionally other resources
into a single EFI executable that UEFI firmware (or a boot loader like systemd-boot)
can boot directly.

[uki]: https://uapi-group.org/specifications/specs/unified_kernel_image/
[ukify-man]: https://www.freedesktop.org/software/systemd/man/latest/ukify.html
[systemd]: https://systemd.io/

To enable this, set the `ukify` key to `true` in the TOML footer:
```toml
ukify = true
```
This will:

* add a build-dependency on `systemd-ukify` (which provides the `ukify` command),
* build the kernel image into a UKI using the [UEFI stub] bundled with this release of
  ukpack for your target architecture, and
* install that UKI in place of the plain kernel image in both the
  `linux-image-<version>` and `linux-modules-<version>` packages.

[UEFI stub]: https://www.freedesktop.org/software/systemd/man/latest/systemd-stub.html

> **Note:** bundled stub files (`linux<efiarch>.efi.stub`) are currently only shipped
> for the `resolute` release. Setting `ukify = true` for other releases will fail
> because there is no bundled stub to use.

If you want to use your own build of the stub - for example to use it on a release
that doesn't bundle one, or to pin a specific stub version - set `ukify` to a path
to that stub file instead of `true`:
```toml
ukify = "/absolute/path/to/linux<efiarch>.efi.stub"
```
This value is passed unmodified to `ukify build --stub` when the kernel is built, so
it must be reachable from the build environment. In particular it is *not* resolved
relative to the changelog/metadata file (unlike `config`); use an absolute path, or a
path relative to the top of your kernel source tree since that's the directory
`dpkg-buildpackage` is invoked from.

`ukify` support is currently only implemented for these architectures, and the
`<efiarch>` placeholder above corresponds to:

| Debian architecture  | `<efiarch>` |
| -------------------- | ----------- |
| `i386`               | `ia32`      |
| `amd64`              | `x64`       |
| `armhf`              | `arm`       |
| `arm64`              | `aa64`      |
| `riscv64`            | `riscv64`   |

As with `config`, `ukify` can be set per architecture. Since an unset (or falsy) value
means "disabled", the simplest way to only enable it for some architectures is to only
set it under those architectures, without a top-level `ukify` key:
```toml
arch = "amd64 arm64"
[amd64]
ukify = true
[arm64]
ukify = "/path/to/my/arm64-stub.efi"
```

The `ukify build` invocation used by ukpack only bundles the kernel image with the
stub - it does not currently pass a kernel command line, initrd, or other resources to
`ukify`. See the [ukify manual page][ukify-man] for the full set of things a UKI can
contain, in case you want to add these to the built UKI yourself afterwards.

If the kernel build produces an `arch/<arch>/boot/dts/dtbs-list` file (i.e. `CONFIG_OF=y`
and the architecture builds separate device-tree blobs), ukify build is passed
`--devicetree-auto` for every entry in that list ending in `.dtb`, so that the
appropriate device-tree blob for the booted hardware is picked automatically and
bundled into the UKI. Device-tree overlay files (`.dtbo`) listed there are *not*
included, since `ukify`/`systemd-stub` do not support boot-time selection of overlays
the way it does for base device trees.

### Update your kernel

To create a new version of your kernel,
you can use the Debian `dch` tool to update the changelog/metadata file
although it will complain a bit about the TOML footer.
```
dch -ic example.toml
```

Just make sure to bump the version number as described above
and set the release to the Ubuntu release you want to build the kernel for.

### Build it locally

When testing new features, patches or configurations it can be useful to build the kernel locally before uploading it to a PPA.
This can easily be achieved with the `-D/--debian` option:
```sh
cd /path/to/your/kernel
rm -rf debian # to remove earlier versions
/path/to/ukpack -D example.toml
dpkg-buildpackage -b
ls ../*.deb
```
This will build the kernel and create the packages in `..`.

One can even cross-compile the kernel this way. Eg. for RISC-V it would be
```sh
dpkg-buildpackage -Pcross -a riscv64 -b
```
However the kernel tools as well as header package cannot easily be cross-compiled so
cross-compiling will only produce the kernel image, modules and `linux-image-<name>` meta package.

### Don't build certain packages

When building a kernel ukpack will also build tools, header packages and other
binary artifactes that are tied to the kernel and package them into multiple
different binary packages.
However sometimes it can be useful to skip building some of them either because
building them fails or to save time building packages you don't need.

This can be achieved by setting the `enabled` key to `false` for any of the
packages. Eg. to disable building the `linux-main-modules-zfs` package with the
out-of-tree ZFS modules set this in the TOML footer:
```toml
[pkg.lmm-zfs]
enabled = false
```

You can even disable everything but just the kernel image and modules with
```toml
[pkg]
meta.enabled = false
meta-headers.enabled = false
meta-tools.enabled = false
headers.enabled = false
tools.enabled = false
lmm-zfs.enabled = false
```

If your kernel builds on multiple architectures you can disable packages on just
some of them by overwriting the `Architecture` key. Eg.
```toml
arch = "amd64 arm64 armhf riscv64"
# disable the ZFS module only on armhf
[pkg.lmm-zfs]
Architecture = "amd64 arm64 riscv64"
```

## License

This project is licensed under the [GPL v2][gpl-2.0] license.

[gpl-2.0]: https://opensource.org/license/gpl-2-0
