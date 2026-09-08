# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

PKG_NAME="moonlight"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/moonlight-stream/moonlight-embedded"
PKG_DEPENDS_TARGET="toolchain opus SDL2 libevdev alsa curl enet avahi ffmpeg"
PKG_LONGDESC="Moonlight is an open source implementation of NVIDIA's GameStream, as used by the NVIDIA Shield, but built for Linux."

PKG_PATCH_DIRS+=" ${DEVICE}"

PKG_URL="${PKG_SITE}.git"
PKG_VERSION="775444287305849ebdf4736c75298ad0713e2d5d" # v2.7.1
PKG_TOOLCHAIN="cmake"

PKG_CMAKE_OPTS_TARGET+=" -DENABLE_CEC=OFF"

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/config/moonlight
  cp -R ${PKG_BUILD}/moonlight.conf ${INSTALL}/usr/config/moonlight
  rm ${INSTALL}/usr/etc/moonlight.conf
  rm ${INSTALL}/usr/share/moonlight/gamecontrollerdb.txt
}

if [ ! "${OPENGL}" = "no" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
fi

if [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

if [ "${VULKAN_SUPPORT}" = "yes" ]
  then
  PKG_DEPENDS_TARGET+=" ${VULKAN}"
fi
