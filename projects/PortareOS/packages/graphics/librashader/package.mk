# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="librashader"
PKG_LICENSE="MPLv2"
PKG_VERSION="87e8a97b50516d997defeaa168173dcd185d4022" # v0.12.0
PKG_SITE="https://github.com/SnowflakePowered/librashader"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain cargo:host cargo rust glfw"
PKG_LONGDESC="Librashader is a preprocessor, compiler, and runtime for RetroArch 'slang' shaders, rewritten in pure Rust."
PKG_TOOLCHAIN="manual"

make_target() {
  unset CMAKE

  cargo build \
    --target ${TARGET_NAME} \
    --features stable \
    --release
}

makeinstall_target() {
  mkdir -p ${SYSROOT_PREFIX}/usr/lib/pkgconfig
  mkdir -p ${SYSROOT_PREFIX}/usr/include/librashader
  mkdir -p ${INSTALL}/usr/lib

  cp ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/liblibrashader_capi.so ${SYSROOT_PREFIX}/usr/lib/librashader.so.2
  ln -sf ${SYSROOT_PREFIX}/usr/lib/librashader.so.2 ${SYSROOT_PREFIX}/usr/lib/librashader.so

  cp ${PKG_BUILD}/pkg/librashader.pc ${SYSROOT_PREFIX}/usr/lib/pkgconfig/librashader.pc
  cp ${PKG_BUILD}/include/* ${SYSROOT_PREFIX}/usr/include/librashader/

  cp ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/liblibrashader_capi.so ${INSTALL}/usr/lib/librashader.so.2
  ln -sf ${INSTALL}/usr/lib/librashader.so.2 ${INSTALL}/usr/lib/librashader.so
}
