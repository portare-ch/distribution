# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="core-info"
PKG_VERSION="5a74858ab2f7a50cebb5a6330895bc38899531c0"
PKG_SHA256="8fbcbfb2ae5bbeaacafb385db464b1d8778cf6680e567ad8d4a5ff1345e61c86"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/libretro/libretro-core-info"
PKG_URL="https://github.com/libretro/libretro-core-info/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Mirror of libretro's core info files"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  ${TOOLCHAIN}/bin/rename mednafen beetle ${PKG_BUILD}/*.info

  mkdir -p ${INSTALL}/usr/lib/libretro
    cp -a ${PKG_BUILD}/*.info ${INSTALL}/usr/lib/libretro/
}
