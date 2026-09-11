# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2018-present Frank Hartung (supervisedthinking (@) gmail.com)
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

PKG_NAME="vulkan-loader"
PKG_VERSION="1.4.359"
PKG_SHA256="c40f7d49496f1561a9a7147da783cff34bfdc8d242dd4134e05bff59d1b7bf79"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://github.com/KhronosGroup/Vulkan-Loader"
PKG_URL="https://github.com/KhronosGroup/Vulkan-Loader/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python3:host vulkan-headers wayland libxcb libX11 libXrandr"
PKG_LONGDESC="Vulkan Installable Client Driver (ICD) Loader."

# This exists only to build all three WSI platforms. The base package gates
# them on DISPLAYSERVER, which is "wl" here, so it builds the Wayland WSI
# alone.
#
# That is wrong for this image. sway depends on xwayland, so X11 clients run,
# and several of them reach Vulkan through Xlib: rpcs3 compiles
# vk::instance::create_swapchain against vkCreateXlibSurfaceKHR, and gamescope,
# armsx2-sa and minivmacsa all link libX11. A loader without those entrypoints
# leaves them undefined at link time. rpcs3 failed exactly that way when this
# override was deleted in #81:
#
#   ld.bfd: undefined reference to `vkCreateXlibSurfaceKHR'
#
# Wayland-first is not Wayland-only while Xwayland is shipped. Do not simplify
# this back to the base package without removing Xwayland first.
#
# The version tracks the base tree deliberately: these three Khronos packages
# are one version-locked set with vulkan-headers and vulkan-tools, so bump them
# together or not at all.

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DBUILD_TESTS=OFF \
                         -DBUILD_WSI_XCB_SUPPORT=ON \
                         -DBUILD_WSI_XLIB_SUPPORT=ON \
                         -DBUILD_WSI_WAYLAND_SUPPORT=ON"

  # GAS / GNU Assembler is only supported by aarch64 & x86_64
  if [ "${ARCH}" = "arm" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DUSE_GAS=OFF"
  fi
}
