# Instructions for creating the Debian Bookworm sysroots

- Use Ubuntu or Debian linux (both `arm64` and `amd64`) to create the sysroots.

- Install the following packages:

```bash
sudo apt update
sudo apt install debootstrap
```

- Sudo as root
  
- For `arm64` sysroot, use the following command on a `arm64` machine:

```bash
mkdir -p /opt/debian-bookworm-sysroot-arm64
debootstrap --arch=arm64 --variant=buildd --include=build-essential stable /opt/debian-bookworm-sysroot-arm64 http://deb.debian.org/debian
cd /opt/debian-bookworm-sysroot-arm64
tar --xz -cpf ../debian-bookworm-sysroot-arm64.tar.xz --numeric-owner --xattrs --acls --exclude='usr/share/man/*' --exclude='var/cache/apt/archives/*.deb' --exclude='*/*:*' .
cd ..
sha256sum ./debian-bookworm-sysroot-arm64.tar.xz
```

- For `amd64` sysroot, use the following command on a `amd64` machine:

```bash
mkdir -p /opt/debian-bookworm-sysroot-amd64
debootstrap --arch=amd64 --variant=buildd --include=build-essential stable /opt/debian-bookworm-sysroot-amd64 http://deb.debian.org/debian
cd /opt/debian-bookworm-sysroot-amd64
tar --xz -cpf ../debian-bookworm-sysroot-amd64.tar.xz --numeric-owner --xattrs --acls --exclude='usr/share/man/*' --exclude='var/cache/apt/archives/*.deb' --exclude='*/*:*' .
cd ..
sha256sum ./debian-bookworm-sysroot-amd64.tar.xz
```
