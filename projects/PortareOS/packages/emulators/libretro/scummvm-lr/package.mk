# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

PKG_NAME="scummvm-lr"
PKG_VERSION="fcbce3ae815269dacdc309092bc92ccc6d3e13bb"
PKG_SHA256="7e60fec38740f90bb987c79d8f8623faa48485373907d3a15a13b0b3b353a316"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/libretro/scummvm"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain soundfont-generaluser"
PKG_LONGDESC="ScummVM as a libretro core: the adventure engines, with their MIDI synth built in"
PKG_TOOLCHAIN="make"

# The core's Makefile fetches libretro-deps and libretro-common itself, at
# the commits it names, and builds what it needs from them: zlib, png,
# freetype, vorbis, FluidLite and the rest are compiled in. No fluidsynth
# on the image, then: the synth is FluidLite inside the core, per game,
# and the soundfont it plays is the one the shipped scummvm.ini names.
# `all` builds the core and scummvm.zip, the data files and themes of
# this exact version, which have to travel with it.
PKG_MAKE_OPTS_TARGET="-C backends/platform/libretro platform=unix all"

makeinstall_target() {
  local LR="${PKG_BUILD}/backends/platform/libretro"
  mkdir -p ${INSTALL}/usr/lib/libretro
    cp -a "${LR}/scummvm_libretro.so" ${INSTALL}/usr/lib/libretro

  # The bundle unpacks to scummvm/theme and scummvm/extra, the layout the
  # core looks for under RetroArch's system directory. post-update copies
  # it there (/storage/roms/bios/scummvm) after every update, so the data
  # always matches the core.
  mkdir -p ${INSTALL}/usr/share
    unzip -qo "${LR}/scummvm.zip" -d ${INSTALL}/usr/share

  # The ini the core starts from, once, next to that: post-update puts it
  # in place only when there is none, since it is where added games live.
  mkdir -p ${INSTALL}/usr/config/scummvm
    cp -a ${PKG_DIR}/config/scummvm.ini ${INSTALL}/usr/config/scummvm
}
