#!/bin/bash

DISTRO="debian"
VERSION="bookworm"
MIRROR="http://deb.debian.org/debian/"
ARCH="x86_64"
FOLDER="/opt"
VARIANT="buildd" # buildd, minbase, core, standard, etc.
PACKAGES=""

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
    --variant=*)
      VARIANT="${arg#*=}"
      ;;
    --packages=*)
      PACKAGES="${arg#*=}"
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

COMPONENTS="main"

if [ "$DISTRO" == "ubuntu" ]; then
  COMPONENTS="main,restricted,universe,multiverse"
else
  # Debian (bookworm, trixie, etc.)
  COMPONENTS="main,contrib,non-free,non-free-firmware"
fi

echo "Downloading sysroot from ${MIRROR}..."
args="--arch=${ARCH} --variant=${VARIANT} --components=${COMPONENTS}"

if [ -n "${PACKAGES}" ]; then
  args+=" --include=${PACKAGES}"
fi

if [ "$DISTRO" == "ubuntu" ]; then
  args+=" --extra-suites=${VERSION}-updates,${VERSION}-security"
elif [ "$DISTRO" == "debian" ]; then
  args+=" --extra-suites=${VERSION}-updates"
fi

echo "Running debootstrap..."
echo "debootstrap ${args} ${VERSION} ${SYSROOT_DIR} ${MIRROR}"
debootstrap \
    ${args} \
    ${VERSION} ${SYSROOT_DIR} ${MIRROR}

echo "Configuring repositories and updating..."

# Mount necessary filesystems
mount -t proc /proc "${SYSROOT_DIR}/proc"
mount -t sysfs /sys "${SYSROOT_DIR}/sys"
mount -o bind /dev "${SYSROOT_DIR}/dev"
mount -o bind /dev/pts "${SYSROOT_DIR}/dev/pts"

# Setup sources.list
if [ "$DISTRO" == "debian" ]; then
  cat <<EOF > "${SYSROOT_DIR}/etc/apt/sources.list"
deb ${MIRROR} ${VERSION} ${COMPONENTS//,/ }
deb ${MIRROR} ${VERSION}-updates ${COMPONENTS//,/ }
deb http://security.debian.org/debian-security ${VERSION}-security ${COMPONENTS//,/ }
EOF
elif [ "$DISTRO" == "ubuntu" ]; then
  cat <<EOF > "${SYSROOT_DIR}/etc/apt/sources.list"
deb ${MIRROR} ${VERSION} ${COMPONENTS//,/ }
deb ${MIRROR} ${VERSION}-updates ${COMPONENTS//,/ }
deb http://security.ubuntu.com/ubuntu ${VERSION}-security ${COMPONENTS//,/ }
EOF
fi

# Upgrade
chroot "${SYSROOT_DIR}" apt update
chroot "${SYSROOT_DIR}" apt --fix-broken install -y
chroot "${SYSROOT_DIR}" apt upgrade -y
chroot "${SYSROOT_DIR}" env DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y

# Cleanup mounts
umount "${SYSROOT_DIR}/dev/pts"
umount "${SYSROOT_DIR}/dev"
umount "${SYSROOT_DIR}/sys"
umount "${SYSROOT_DIR}/proc"

echo "Stripping sysroot of unnecessary files..."
# Documentation and locales
rm -rf "${SYSROOT_DIR}"/usr/share/{doc,man,info,locale,lintian,bug,zoneinfo}

# Graphic assets and themes
rm -rf "${SYSROOT_DIR}"/usr/share/{icons,pixmaps,fonts,themes,wallpapers,backgrounds,sounds}
rm -rf "${SYSROOT_DIR}"/usr/share/common-licenses
rm -rf "${SYSROOT_DIR}"/usr/share/dict

# Games
rm -rf "${SYSROOT_DIR}"/usr/games

# Apt caches and lists (keep sources.list)
rm -rf "${SYSROOT_DIR}"/var/cache/apt/*
rm -rf "${SYSROOT_DIR}"/var/lib/apt/lists/*

# Logs and temp files
rm -rf "${SYSROOT_DIR}"/var/log/*
rm -rf "${SYSROOT_DIR}"/var/tmp/*
rm -rf "${SYSROOT_DIR}"/tmp/*
rm -rf "${SYSROOT_DIR}"/var/mail
rm -rf "${SYSROOT_DIR}"/var/spool

# Systemd units (not needed for sysroot)
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/multi-user.target.wants/*
rm -rf "${SYSROOT_DIR}"/etc/systemd/system/*.wants/*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/local-fs.target.wants/*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/sockets.target.wants/*udev*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/sockets.target.wants/*initctl*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup*
rm -rf "${SYSROOT_DIR}"/lib/systemd/system/systemd-update-utmp*

# QEMU static binaries
rm -rf "${SYSROOT_DIR}"/usr/bin/qemu-*-static

# Apt archives
rm -rf "${SYSROOT_DIR}"/var/cache/apt/archives/*.deb

# Kernel modules and boot files (not needed for userspace dev)
rm -rf "${SYSROOT_DIR}"/lib/modules
rm -rf "${SYSROOT_DIR}"/boot/*

# Package management info (prevents future apt/dpkg usage, but saves space)
rm -rf "${SYSROOT_DIR}"/var/lib/dpkg
rm -rf "${SYSROOT_DIR}"/var/lib/apt

# Backups and old configs
rm -rf "${SYSROOT_DIR}"/var/backups
rm -rf "${SYSROOT_DIR}"/etc/*.save
rm -rf "${SYSROOT_DIR}"/etc/*.bak

# Udev and init scripts
rm -rf "${SYSROOT_DIR}"/lib/udev
rm -rf "${SYSROOT_DIR}"/etc/init.d
rm -rf "${SYSROOT_DIR}"/etc/rc*.d

# Internationalization and additional docs
rm -rf "${SYSROOT_DIR}"/usr/share/i18n
rm -rf "${SYSROOT_DIR}"/usr/share/doc-base

# Systemd state
rm -rf "${SYSROOT_DIR}"/var/lib/systemd

# Empty mount points and unused dirs
rm -rf "${SYSROOT_DIR}"/media "${SYSROOT_DIR}"/mnt "${SYSROOT_DIR}"/srv

# Python cache (if any)
find "${SYSROOT_DIR}" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

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
