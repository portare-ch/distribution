# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="portmaster"
PKG_VERSION="2026.05.04-1202"
PKG_SHA256="9d6f25d461afced95569923a57c6a9c42df225190c043d74fe2ec0edcf40a477"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/PortsMaster/PortMaster-GUI"
PKG_URL="https://github.com/PortsMaster/PortMaster-GUI/releases/download/${PKG_VERSION}/PortMaster.zip"
PKG_DEPENDS_TARGET="toolchain portareos-hotkey gamecontrollerdb oga_controls control-gen xmlstarlet list-guid gst-plugins-base"
PKG_LONGDESC="Portmaster - a simple tool that allows you to download various game ports"
PKG_TOOLCHAIN="manual"

COMPAT_URL="https://github.com/ROCKNIX/packages/raw/main/compat.tar.gz" #f0f5e94

makeinstall_target() {
  export STRIP=true

  mkdir -p ${INSTALL}/usr/config/PortMaster
    cp -a ${PKG_DIR}/sources/* ${INSTALL}/usr/config/PortMaster

  mkdir -p ${INSTALL}/usr/bin
    cp -a ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/config/PortMaster/release
    curl -Lo ${INSTALL}/usr/config/PortMaster/release/PortMaster.zip ${PKG_URL}

  mkdir -p ${INSTALL}/usr/lib/compat
    curl -Lo ${PKG_BUILD}/compat.tar.gz ${COMPAT_URL}
    tar -xvf ${PKG_BUILD}/compat.tar.gz -C ${INSTALL}/usr/lib
    # Keep the real SDL2 this tarball ships. Ports are prebuilt aarch64
    # binaries linked against real SDL2, and the system libSDL2 is now
    # sdl2-compat. ROCKNIX ran that pairing for three weeks and saw ports
    # segfault - Apotris and Aquaria confirmed - with scaling and audio
    # faults besides. control.txt exports LD_LIBRARY_PATH=/usr/lib/compat
    # for every port, so the ports find this one first and everything
    # else in the image keeps the shim.
    if [ "${PREFER_GLES}" = "yes" ]; then
      mv ${INSTALL}/usr/lib/compat/libSDL2-2.0.so.0.gles ${INSTALL}/usr/lib/compat/libSDL2-2.0.so.0
    else
      rm -rf ${INSTALL}/usr/lib/compat/libSDL2-2.0.so.0.gles
    fi
}
