# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="extra-firmware"
PKG_VERSION="30c56e2f34af37fe372166b739d6ab277f5155b5"
PKG_SHA256="b6e422b953fec72666a84c0060f1ac32dd3fce452a6d6311e5051ab923497600"
PKG_LICENSE="proprietary"
PKG_SITE="https://github.com/ROCKNIX/extra-firmware"
PKG_URL="https://github.com/ROCKNIX/extra-firmware/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="extra-firmware: Extra kernel firmware needed for PortareOS devices"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_firmware_dir)

  case "${DEVICE}" in
    "SM6115") cp -a SM6115/* ${INSTALL}/$(get_full_firmware_dir) ;;
    "SM8250") cp -a SM8250/* ${INSTALL}/$(get_full_firmware_dir) ;;
    "SM8550") cp -a SM8550/* ${INSTALL}/$(get_full_firmware_dir) ;;
    "SM8650") cp -a SM8650/* ${INSTALL}/$(get_full_firmware_dir) ;;
    "SM8750") cp -a SM8750/* ${INSTALL}/$(get_full_firmware_dir) ;;
  esac

  if [ "${DEVICE}" = "SM8550" ]; then
    # ROCKNIX's SM8550 folder carries every SM8550 handheld's signed DSP
    # firmware. The Nova's device tree (rpnova including rp6) loads
    # ayn/odin2/adsp.mbn and ayn/cdsp.mbn - which is what dmesg shows on
    # the device - so the other devices' 117 MB can never be loaded here.
    # Listed rather than "everything but odin2", so a folder upstream adds
    # later is kept until someone decides otherwise.
    FW=${INSTALL}/$(get_full_firmware_dir)/qcom/sm8550
    rm -rf ${FW}/ayaneo ${FW}/ayn/thor ${FW}/ayn/odin2portal ${FW}/ayn/odin2mini

    python3 ${PKG_DIR}/sources/tplg-allow-44100.py \
      ${INSTALL}/$(get_full_firmware_dir)/qcom/sm8550/AYN-Odin2-tplg.bin
  fi
}
