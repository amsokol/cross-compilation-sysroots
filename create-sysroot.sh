#!/bin/bash

DISTRO="ubuntu"
VERSION="noble"
MIRROR="http://archive.ubuntu.com/ubuntu/"
ARCH="x86_64"
FOLDER="/opt"
COMPONENTS="main,restricted,universe,multiverse"

# Parse args
for arg in "$@"; do
  case $arg in
    --distro=*)
      DISTRO="${arg#*=}"
      ;;
    --version=*)
      VERSION="${arg#*=}"
      ;;
    --mirror=*)
      MIRROR="${arg#*=}"
      ;;
    --arch=*)
      ARCH="${arg#*=}"
      ;;
    --out=*)
      FOLDER="${arg#*=}"
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

SYSROOT_DIR="${FOLDER}/${DISTRO}-${VERSION}-sysroot-${ARCH}"
SYSROOT_ZIP="${FOLDER}/${DISTRO}-${VERSION}-sysroot-${ARCH}.tar.xz"

echo "Creating sysroot for ${DISTRO} ${VERSION} (${ARCH})..."
echo "Distro mirror: ${MIRROR}"
echo "Sysroot folder: ${SYSROOT_DIR}"
echo "Sysroot zip: ${SYSROOT_ZIP}"

echo "Removing ${SYSROOT_ZIP} if exists..."
[ -f ${SYSROOT_ZIP} ] && rm ${SYSROOT_ZIP}

echo "Removing ${SYSROOT_DIR} if exists..."
[ -d ${SYSROOT_DIR} ] && rm -rf ${SYSROOT_DIR}

echo "Creating sysroot folder ${SYSROOT_DIR}..."
mkdir -p ${SYSROOT_DIR}

echo "Downloading sysroot from ${MIRROR}..."
debootstrap \
    --arch=${ARCH} \
    --variant=buildd \
    --components=${COMPONENTS} \
    --include=build-essential \
    ${VERSION} ${SYSROOT_DIR} ${MIRROR}

echo "Update and upgrade sysroot..."
chroot "${SYSROOT_DIR}" /bin/bash -c "
  apt update -y &&
  apt dist-upgrade -y &&
  apt upgrade -y &&
  apt clean
"

echo "Stripping sysroot of unnecessary files..."
rm -rf "${SYSROOT_DIR}"/usr/share/{doc,man,info,locale,lintian,bug,zoneinfo}
rm -rf "${SYSROOT_DIR}"/var/cache/apt/*
rm -rf "${SYSROOT_DIR}"/var/lib/apt/lists/*

rm -rf "${SYSROOT_DIR}"/var/tmp/*
rm -rf "${SYSROOT_DIR}"/tmp/*

rm -rf "${SYSROOT_DIR}"/lib/systemd/system/multi-user.target.wants/*
rm -rf "${SYSROOT_DIR}"/etc/systemd/system/*.wants/*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/local-fs.target.wants/*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/sockets.target.wants/*udev*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/sockets.target.wants/*initctl*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/systemd-update-utmp*

rm -rf "${SYSROOT_DIR}"/usr/bin/qemu-*-static

rm -rf "${SYSROOT_DIR}"/var/cache/apt/archives/*.deb

find "${SYSROOT_DIR}"/var/log -type f -delete

echo "Stripping binaries..."
find "${SYSROOT_DIR}" -type f -executable -exec strip --strip-unneeded {} + 2>/dev/null || true

echo "Sysroot size:"
du -sh "$SYSROOT_DIR"

echo "Zipping sysroot to ${SYSROOT_ZIP}..."
tar -C ${SYSROOT_DIR} --xz -cpf ${SYSROOT_ZIP} --numeric-owner --xattrs --acls \
    --exclude='*/*:*' \
    .

echo "Sysroot created successfully at ${SYSROOT_ZIP}."

echo "Cleaning up..."
rm -rf ${SYSROOT_DIR}

echo "Done."
echo "You can now use the sysroot at ${SYSROOT_ZIP}."
hash=$(sha256sum ${SYSROOT_ZIP} | cut -d ' ' -f1)
echo "sha256: $hash"
