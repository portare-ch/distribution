# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="neocd_lr"
PKG_VERSION="3118c6901787e863e80e79170d02d47657b3b0ab"
PKG_SHA256="01743b658e85aef7555fb91e3c0f5e854cbe4350d8fd543fddb9fb5847c099f4"
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://github.com/libretro/neocd_libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain flac libogg libvorbis"
PKG_LONGDESC="Neo Geo CD emulator for libretro "

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
    cp -a ${PKG_BUILD}/neocd_libretro.so ${INSTALL}/usr/lib/libretro
}
