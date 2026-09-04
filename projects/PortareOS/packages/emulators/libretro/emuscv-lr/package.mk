# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="emuscv-lr"
PKG_VERSION="dfce10df090ce3f5eb23bdbee289702ec1478246"
PKG_SHA256="f94c59fc91baa4dc8e96233bf0ec710fe1aaf79baa35c0b5af7fe42f73754fec"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://gitlab.com/MaaaX-EmuSCV/libretro-emuscv"
PKG_URL="${PKG_SITE}/-/archive/${PKG_VERSION}/libretro-emuscv-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain bin2c:host SDL2"
PKG_DEPENDS_UNPACK="glibc"
PKG_LONGDESC="An EPOCH/YENO Super Cassette Vision (1984) home video game emulator for Libretro"
PKG_TOOLCHAIN="make"

PKG_MAKE_OPTS_TARGET="platform=unix"

# emuscv includes <sys/io.h>, x86 port I/O, which aarch64 glibc does not
# ship. It only needs the header to parse: the inb/outb helpers in it are
# static inline and never called, so nothing x86 reaches the assembler.
# Upstream pointed CXXFLAGS straight into glibc's *build* directory for it.
# That directory is AUTOREMOVE's to delete the moment nothing in the plan
# still references glibc, and a retried job then compiles against a path
# that no longer exists: "fatal error: sys/io.h: No such file or directory".
# glibc is our PKG_DEPENDS_UNPACK, so it is guaranteed present right here,
# at post_unpack; copying the one header into our own tree then means our
# build never depends on that directory's lifetime again.
post_unpack() {
  mkdir -p "${PKG_BUILD}/.x86-compat/sys"
  cp "$(get_build_dir glibc)/sysdeps/unix/sysv/linux/x86/sys/io.h" \
     "${PKG_BUILD}/.x86-compat/sys/io.h"
}

pre_configure_target() {
  export TERM=xterm
  [ -f "${PKG_BUILD}/.x86-compat/sys/io.h" ] || die "emuscv-lr: sys/io.h was not captured at unpack; is glibc still in PKG_DEPENDS_UNPACK?"
  CXXFLAGS+=" -I${PKG_BUILD}/.x86-compat"
  sed -i 's~tools/bin2c/~'${TOOLCHAIN}'/usr/bin/~g' Makefile.libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
    cp -a ${PKG_BUILD}/emuscv_libretro.so ${INSTALL}/usr/lib/libretro
}
