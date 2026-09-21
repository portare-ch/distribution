# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

# Inherit PKG_VERSION, PKG_SHA256 and PKG_URL rather than restating them.
# This override sat on 1.6.40 while the global recipe carried 1.6.58 -
# eighteen patch releases of an image parser that every frontend on the
# device feeds untrusted files to.
. ${ROOT}/packages/graphics/libpng/package.mk

PKG_DEPENDS_HOST="zlib:host"
PKG_DEPENDS_TARGET="toolchain zlib"
PKG_BUILD_FLAGS="+pic +pic:host"

# Shared on target, unlike the global recipe: everything here links libpng
# dynamically, and a static one would be duplicated into each consumer.
PKG_CONFIGURE_OPTS_TARGET="ac_cv_lib_z_zlibVersion=yes \
                           --enable-static \
                           --enable-shared"

PKG_CONFIGURE_OPTS_HOST="--enable-static --disable-shared"

pre_configure_host() {
  export CPPFLAGS="$CPPFLAGS -I${TOOLCHAIN}/include"
}

pre_configure_target() {
  export CPPFLAGS="${CPPFLAGS} -I${SYSROOT_PREFIX}/usr/include"
}

post_makeinstall_target() {
  sed -e "s:\([\"'= ]\)/usr:\\1${SYSROOT_PREFIX}/usr:g" \
      -e "s:libs=\"-lpng16\":libs=\"-lpng16 -lz\":g" \
      -i ${SYSROOT_PREFIX}/usr/bin/libpng*-config

  rm -rf ${INSTALL}/usr/bin
}
