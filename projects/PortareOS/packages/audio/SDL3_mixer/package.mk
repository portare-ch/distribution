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

# emulationstation's audio layer is built on this: it reaches for
# SDL_mixer in four files.
#
# VENDORED=OFF: the release tarball carries a copy of every decoder and
# builds those in preference to the ones the image already has.
#
# DEPS_SHARED stays ON, which is both the default and what SDL2_mixer did
# under autotools: the decoders are dlopened by soname instead of linked.
# Linking them put fluidsynth in this library's NEEDED, and fluidsynth
# wants libgomp, which is not on the sysroot's link path - so every
# consumer failed to link, emulationstation first:
#
#   libfluidsynth.so.3: undefined reference to `GOMP_parallel@GOMP_4.0'
#
# GME defaults to ON and wants game-music-emu, which this image has not
# got, so it has to be named off or configure fails.
PKG_CMAKE_OPTS_TARGET="-DSDLMIXER_VENDORED=OFF \
                       -DSDLMIXER_GME=OFF \
                       -DSDLMIXER_TESTS=OFF \
                       -DSDLMIXER_EXAMPLES=OFF \
                       -DSDLMIXER_INSTALL=ON \
                       -DSDLMIXER_WERROR=OFF"
