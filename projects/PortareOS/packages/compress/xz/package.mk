# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

# Inherit PKG_VERSION, PKG_SHA256 and PKG_URL rather than restating them.
# This override sat on 5.8.1 while the global recipe carried 5.8.3, which
# is a poor place to be behind: xz unpacks every source tarball in the
# build, and is the most scrutinised supply-chain package in the tree.
. ${ROOT}/packages/compress/xz/package.mk

# What follows is this fork's build configuration, which differs from the
# global recipe's and is the reason this override exists at all.
PKG_DEPENDS_HOST="ccache:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_BUILD_FLAGS="+pic +pic:host"
PKG_TOOLCHAIN="configure"

# never build shared or k0p happens when building
# on fedora due to host selinux/liblzma
PKG_CONFIGURE_OPTS_HOST="--disable-shared --enable-static \
                         --disable-lzmadec \
                         --disable-lzmainfo \
                         --enable-lzma-links \
                         --disable-nls \
                         --disable-scripts \
                         --enable-symbol-versions=no"

PKG_CONFIGURE_OPTS_TARGET="--enable-shared \
                          --disable-static \
                          --enable-symbol-versions=yes"

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/bin
}
