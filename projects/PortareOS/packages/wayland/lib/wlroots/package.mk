# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

# Inherit PKG_VERSION, PKG_SHA256 and PKG_URL from the global recipe rather
# than restating them. An override that restates a version stops tracking
# the tree it forked from, silently and forever: this one sat on 0.19.3
# while the global recipe moved to 0.20.2, which is how sway 1.12 came to
# fail with "Run-time dependency wlroots-0.20 found: NO" twice.
#
# This fork builds one device, so the three-way DEVICE case that used to
# live here - two Rockchip vendor forks at 0.17 and 0.19 for boards we do
# not build - is gone with it.
. ${ROOT}/packages/wayland/lib/wlroots/package.mk

# xwayland, which the global recipe disables, and the xcb bits it needs.
# lcms2 is what backs colour management; see the meson options below.
PKG_DEPENDS_TARGET+=" xwayland libxcb xcb-util-wm lcms2"

PKG_MESON_OPTS_TARGET="-Dxcb-errors=disabled \
                       -Dxwayland=enabled \
                       -Dexamples=false \
                       -Drenderers=gles2 \
                       -Dbackends=drm,libinput \
                       -Dcolor-management=enabled"

# Colour management arrived as an option in 0.20 and defaults to "auto",
# which quietly compiles color_fallback.c when lcms2 is missing - a build
# that succeeds and a compositor that advertises the protocol while doing
# nothing with it. sway 1.12's colour management is the reason issue #161
# is possible, so ask for it explicitly and let a missing lcms2 fail the
# build instead of silently removing the feature.

pre_configure_target() {
  # As the global recipe, plus -Wno-return-type, which this toolchain needs
  # and upstream's CI does not see.
  export TARGET_CFLAGS=$(echo "${TARGET_CFLAGS} -Wno-unused-variable -Wno-unused-but-set-variable -Wno-unused-function -Wno-return-type")
}
