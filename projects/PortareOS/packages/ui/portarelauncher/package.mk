# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

PKG_NAME="portarelauncher"
PKG_VERSION="6fb3b7f37eaa56787390368ab9bec52a703f8e57"
PKG_SHA256="dfe19ebc62cd16d79c0e9718c0f8e2268b08dcfd01550b893413319bcb8de16e"
PKG_LICENSE="GPL-2.0"
PKG_SITE="https://github.com/portare-ch/portarelauncher"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libdrm"
PKG_LONGDESC="The front-end: a KMS launcher that owns the panel directly."
PKG_TOOLCHAIN="make"

# libdrm and libc, and that is the whole list. No GBM, EGL, Vulkan or Mesa -
# a text screen on a black field is a dumb buffer and a memcpy, so the GPU
# never leaves idle while the menu is up.

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp -a ${PKG_BUILD}/portarelauncher ${INSTALL}/usr/bin
}
