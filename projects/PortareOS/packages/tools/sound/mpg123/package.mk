# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

. ${ROOT}/packages/addons/addon-depends/multimedia-tools-depends/mpg123/package.mk

PKG_DEPENDS_TARGET+=" SDL2 openal-soft"
PKG_BUILD_FLAGS="+pic"

# Deliberately empty, where the base recipe sets --disable-shared
# --enable-static. Two things link libmpg123 here, SDL2_mixer and gmu, so it is
# built shared for them to share. This was an "unset" at the bottom of the
# file, below a block it silently cancelled; saying it here says what it does.
PKG_CONFIGURE_OPTS_TARGET=""
