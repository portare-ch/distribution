# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

# Inherit PKG_VERSION, PKG_SHA256 and PKG_URL from the global recipe rather
# than restating them. This override sat on 1.11 while the global recipe
# carried 1.12, which held the whole image a release behind for no reason
# anyone had decided on - the same drift that kept iwd on 3.10 and wlroots
# on 0.19.3.
. ${ROOT}/packages/wayland/compositor/sway/package.mk

# xwayland and the toolkit bits the global recipe leaves out, plus xkbcomp
# and xterm, which sway expects to find at runtime.
PKG_DEPENDS_TARGET+=" glib xwayland xkbcomp xterm libthai xcb-util-wm"
PKG_TOOLCHAIN="meson"
PKG_PATCH_DIRS+="${DEVICE}"

PKG_MESON_OPTS_TARGET="-Ddefault-wallpaper=false \
                       -Dzsh-completions=false \
                       -Dbash-completions=false \
                       -Dfish-completions=false \
                       -Dswaybar=true \
                       -Dswaynag=true \
                       -Dtray=disabled \
                       -Dgdk-pixbuf=enabled \
                       -Dman-pages=disabled \
                       -Dsd-bus-provider=auto \
                       -Dwerror=false"

# sway carries werror=true in its own meson default_options, so any warning
# the toolchain raises is a build failure. The global recipe meets that with
# an exported -Wno-unused-variable, which only ever covers the warning of
# the day. -Dwerror=false addresses the reason instead, and overrides the
# global pre_configure_target below.

pre_configure_target() {
  :
}

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/sway
  mkdir -p ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/sway.sh     ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/sway-config ${INSTALL}/usr/lib/sway
  mkdir -p ${INSTALL}/usr/lib/autostart/common
    cp ${PKG_DIR}/autostart/111-sway-init     ${INSTALL}/usr/lib/autostart/common
    cp ${PKG_DIR}/scripts/sway-touch.sh     ${INSTALL}/usr/bin

  chmod +x ${INSTALL}/usr/bin/sway*

  # install config & wallpaper
  mkdir -p ${INSTALL}/usr/share/sway
    cp ${PKG_DIR}/config/* ${INSTALL}/usr/share/sway

  # clean up
  safe_remove ${INSTALL}/etc
  safe_remove ${INSTALL}/usr/share/wayland-sessions
}

post_install() {
  enable_service sway-touch.service
}
