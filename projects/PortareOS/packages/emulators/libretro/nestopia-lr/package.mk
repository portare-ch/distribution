# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="nestopia-lr"
PKG_VERSION="92578fdc9445f61dd376138329a938e01d8ba50e"
PKG_SHA256="6a108358f0c71f4a17d017b011389897643b81ddd803abb762395d19a7896789"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/nestopia"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Nestopia UE - cycle-accurate NES / Famicom emulator, reporting the console's exact 60.0988 Hz"
PKG_TOOLCHAIN="make"

PKG_MAKE_OPTS_TARGET="-C libretro"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
    cp -a libretro/nestopia_libretro.so ${INSTALL}/usr/lib/libretro
}
