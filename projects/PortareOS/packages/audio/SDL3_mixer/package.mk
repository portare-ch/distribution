# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

PKG_NAME="SDL3_mixer"
PKG_VERSION="3.2.4"
PKG_SHA256="182a07c745375e113dc740d43964ff21b0be29f29f59876c4dbc4db3d32f6901"
PKG_LICENSE="Zlib"
PKG_SITE="https://www.libsdl.org/projects/SDL_mixer/"
PKG_URL="https://github.com/libsdl-org/SDL_mixer/releases/download/release-${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL3 fluidsynth opusfile libogg libvorbis flac mpg123 wavpack libxmp"
PKG_LONGDESC="SDL3 mixer, the audio half emulationstation needs before it can leave SDL2"
PKG_TOOLCHAIN="cmake"

# Nothing depends on this yet. It is here so the SDL3 side of an
# emulationstation port is a version bump rather than a packaging job:
# ES reaches for SDL_mixer in four files, and SDL3_ttf was already the
# only SDL3 satellite library we carried.
#
# VENDORED=OFF: the release tarball carries a copy of every decoder and
# builds those in preference to the ones the image already has.
# DEPS_SHARED=OFF links them instead of dlopening them by soname.
# GME defaults to ON and wants game-music-emu, which this image has not
# got, so it has to be named off or configure fails.
PKG_CMAKE_OPTS_TARGET="-DSDLMIXER_VENDORED=OFF \
                       -DSDLMIXER_DEPS_SHARED=OFF \
                       -DSDLMIXER_GME=OFF \
                       -DSDLMIXER_TESTS=OFF \
                       -DSDLMIXER_EXAMPLES=OFF \
                       -DSDLMIXER_INSTALL=ON \
                       -DSDLMIXER_WERROR=OFF"
