# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="mediacenter"
PKG_VERSION=""
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://libreelec.tv"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain ${MEDIACENTER}"
PKG_SECTION="virtual"
PKG_LONGDESC="Mediacenter: Metapackage"

# The "MEDIACENTER = kodi" branch that stood here is gone with the Kodi
# packages. MEDIACENTER is not set by any distribution in this tree, so it
# never ran, and it named packages that no longer exist.
#
# This metapackage stays because virtual/image adds it unconditionally -
# [ ! "${MEDIACENTER}" = "no" ] is true when MEDIACENTER is unset - and with
# nothing to expand it resolves to toolchain alone.
