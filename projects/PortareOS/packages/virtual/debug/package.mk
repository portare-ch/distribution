# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

PKG_NAME="debug"
PKG_VERSION=""
PKG_LICENSE="GPL"
PKG_SITE="https://libreelec.tv"
PKG_URL=""
PKG_SECTION="virtual"
PKG_LONGDESC="What a problem on the device gets debugged with: gdb and strace"

# The base set added memtester, kmsxx, libva-utils, valgrind, and ours
# apitrace, renderdoc and nvtop on top. apitrace traces GL and the image
# renders through Vulkan; renderdoc needs a desktop client; nvtop is a
# desktop GPU monitor. None of it was ever in an image, since the set was
# off for official builds. gdb and strace are, from now on.
PKG_DEPENDS_TARGET="toolchain gdb strace"
