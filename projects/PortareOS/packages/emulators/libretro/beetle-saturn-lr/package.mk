# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="beetle-saturn-lr"
PKG_VERSION="1382b85dcad2e98ef9a67426a775ba548eaf0c68"
PKG_SHA256="c57f6852f66e9a9d466e1cf68d7e6ef13b2bc9030aec21d515ca29bcb8f36324"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/beetle-saturn-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Beetle Saturn - Mednafen's Sega Saturn core, software rendered, with aarch64 JITs for the SCU and SCSP DSPs"
PKG_TOOLCHAIN="make"

# patches/001: report the exact NTSC rate, 28636363.63 / 478660 = 59.826105 Hz,
# instead of upstream's rounded 59.8265, so the 119.652237 Hz panel mode is a
# lock. Needs sega_101.bin and mpr-17933.bin in /storage/roms/bios.

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
    cp -a mednafen_saturn_libretro.so ${INSTALL}/usr/lib/libretro
}
