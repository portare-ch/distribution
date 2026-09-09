# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

. ${ROOT}/packages/audio/openal-soft/package.mk

# PipeWire is first in openal-soft's backend list, but it is only compiled in
# when libpipewire-0.3 is visible, so depend on it and fail the build if not.
PKG_DEPENDS_TARGET+=" pipewire"
PKG_CMAKE_OPTS_TARGET+=" -DALSOFT_BACKEND_PIPEWIRE=on \
                         -DALSOFT_REQUIRE_PIPEWIRE=on"
