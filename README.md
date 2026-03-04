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
Downloading https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.8.12.tar.xz
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
apt-get install gcc-riscv64-linux-gnu libc6-dev-riscv64-cross # for the cross compiler
rm -rf debian # to remove earlier versions
/path/to/ukpack -D example.toml
dpkg-buildpackage -a riscv64 -d -b # -d because the build dependencies are not quite right for cross-compiling
```
However the kernel tools as well as header package cannot easily be cross-compiled
so this will only produce the kernel image, modules and `linux-image-` meta package.

## License

This project is licensed under the [GPL v2][gpl-2.0] license.

[gpl-2.0]: https://opensource.org/license/gpl-2-0
