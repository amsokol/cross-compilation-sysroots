# Instructions for creating the Debian Bookworm sysroots

**Prerequisites**: Use Ubuntu or Debian linux (both `arm64` and `amd64`) to create the sysroots.

## Install the following package

```bash
sudo apt update
sudo apt install debootstrap schroot
```

## Login as root

```bash
sudo -i
```

## Create the sysroots for `amd64` architecture

### Create the sysroots for Ubuntu `noble` (v24.04 LTS) `amd64`

```bash
./create-sysroot.sh --distro=ubuntu --version=noble --mirror=http://archive.ubuntu.com/ubuntu/ --arch=amd64 --variant=buildd --out=/opt
```

### Create the sysroots for Debian `bookworm` (v12) `amd64`

```bash
./create-sysroot.sh --distro=debian --version=bookworm --mirror=http://deb.debian.org/debian --arch=amd64 --variant=buildd --out=/opt
```

### Create the sysroots for Debian `trixie` (v13) `amd64`

```bash
./create-sysroot.sh --distro=debian --version=trixie --mirror=http://deb.debian.org/debian --arch=amd64 --variant=buildd --out=/opt
```

## Create the sysroots for `arm64` architecture

### Create the sysroots for Ubuntu `noble` (v24.04 LTS) `arm64`

```bash
./create-sysroot.sh --distro=ubuntu --version=noble --mirror=http://ports.ubuntu.com/ubuntu-ports --arch=arm64 --variant=buildd --out=/opt
```

### Create the sysroots for Debian `bookworm` (v12) `arm64`

```bash
./create-sysroot.sh --distro=debian --version=bookworm --mirror=http://deb.debian.org/debian --arch=arm64 --variant=buildd --out=/opt
```

### Create the sysroots for Debian `trixie` (v13) `arm64`

```bash
./create-sysroot.sh --distro=debian --version=trixie --mirror=http://deb.debian.org/debian --arch=arm64 --variant=buildd --out=/opt
```
