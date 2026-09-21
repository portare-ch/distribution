# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

# Inherit PKG_VERSION, PKG_SHA256 and PKG_URL rather than restating them.
# This override sat on 2.6.4 while the global recipe carried 2.9.2.
. ${ROOT}/packages/network/nfs-utils/package.mk

# Deliberately narrower than the global recipe's dependency list: this
# image installs mount.nfs and nothing else from the package, so libnl,
# libxml2 and readline are not built for it.
PKG_DEPENDS_TARGET="toolchain keyutils libevent libtirpc rpcbind sqlite util-linux"

PKG_CONFIGURE_OPTS_TARGET="--disable-gss \
                           --disable-nfsv41 \
                           --disable-nfsdcld \
                           --disable-nfsrahead \
                           --disable-nfsdcltrack \
                           --disable-ldap"

pre_configure_target() {
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}
}

# Only the client mount helper. The global recipe installs the daemons.
makeinstall_target() {
  mkdir -p "${INSTALL}/usr/sbin/"
    cp -PR utils/mount/mount.nfs "${INSTALL}/usr/sbin/"
    ln -s mount.nfs "${INSTALL}/usr/sbin/mount.nfs4"
    ln -s mount.nfs "${INSTALL}/usr/sbin/umount.nfs"
    ln -s mount.nfs "${INSTALL}/usr/sbin/umount.nfs4"
}
