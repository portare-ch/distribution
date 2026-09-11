# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2018-present Frank Hartung (supervisedthinking (@) gmail.com)
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="vulkan-loader"
PKG_VERSION="1.4.359"
PKG_SHA256="c40f7d49496f1561a9a7147da783cff34bfdc8d242dd4134e05bff59d1b7bf79"
PKG_LICENSE="Apache-2.0"
PKG_SITE="https://github.com/KhronosGroup/Vulkan-Loader"
PKG_URL="https://github.com/KhronosGroup/Vulkan-Loader/archive/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python3:host vulkan-headers wayland libxcb libX11 libXrandr"
PKG_LONGDESC="Vulkan Installable Client Driver (ICD) Loader."

# Every WSI platform is built, rather than gated on DISPLAYSERVER. That gate
# only makes sense when the compositor's protocol is the only one clients can
# use, and it is not: sway depends on xwayland, so X11 clients run here and
# reach Vulkan through Xlib. rpcs3 compiles vk::instance::create_swapchain
# against vkCreateXlibSurfaceKHR, and gamescope, armsx2-sa and minivmacsa all
# link libX11. Building the Wayland WSI alone leaves those undefined at link
# time.

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
