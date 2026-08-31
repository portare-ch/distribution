# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="emulationstation"
PKG_VERSION="9d664e2ffa75d0fcfd129c6598318c61b57ff8f7"
PKG_SHA256="e1639a1d6750c5987caa6b8a31bc560a6b9ed4692ae3f550a4db9e82dbb87daf"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/ROCKNIX/emulationstation-next"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="boost toolchain SDL2 freetype curl freeimage bash rapidjson SDL2_mixer fping p7zip alsa vlc drm_tool pugixml ${OPENGLES}"
PKG_NEED_UNPACK="busybox"
PKG_LONGDESC="Emulationstation emulator frontend"
PKG_BUILD_FLAGS="-gold"

# ROCKNIX, not PortareOS: this is upstream's CMake option name. ES declares
# option(ROCKNIX ...) and guards 54 blocks of C++ on #ifdef ROCKNIX. Renaming
# it here does not rename it there; CMake just ignores an unknown option, the
# option stays OFF, and every handheld-specific path silently compiles out of
# a build that otherwise succeeds.
PKG_CMAKE_OPTS_TARGET+=" -DROCKNIX=1 \
                         -DDISABLE_KODI=1 \
                         -DENABLE_FILEMANAGER=0 \
                         -DCEC=0 \
                         -DENABLE_PULSE=1 \
                         -DUSE_SYSTEM_PUGIXML=1 \
                         -DGLES3=1"

[ "${DEVICE}" = "S922X" ] && PKG_CMAKE_OPTS_TARGET+=" -DBATTERYPLUS=1"

pre_configure_target() {
  for key in SCREENSCRAPER_DEV_LOGIN \
             GAMESDB_APIKEY \
             CHEEVOS_DEV_LOGIN; do
    if [ -z "${!key}" ]; then
      echo "WARNING: ${key} not declared, will not build support."
    else
      echo "USING: ${key} = ${!key}"
    fi
  done

  export DEVICE=$(echo ${DEVICE^^} | sed "s#-#_##g")

  # ES is upstream's, fetched at build time, and still calls the OS scripts and
  # reads the settings keys under their ROCKNIX names: rocknix-bluetooth,
  # rocknix-config, rocknix-keyboard, the rocknix-automount unit, and keys like
  # rocknix.mangohud.enabled. We renamed all of those, so without this the
  # frontend builds and runs while bluetooth pairing, the settings menus, the
  # on-screen keyboard, bezels, updates and scraping quietly do nothing.
  #
  # Rewritten here rather than carried as a patch, so a call site added upstream
  # is covered by the next version bump instead of failing silently. rocknix.org
  # is protected first: it is a URL, not an interface.
  local guard="@@ROCKNIX_DOT_ORG@@"
  grep -rlZ 'rocknix' "${PKG_BUILD}" 2>/dev/null \
    | xargs -0 -r sed -i \
        -e "s|rocknix[.]org|${guard}|g" \
        -e 's|rocknix-|portareos-|g' \
        -e 's|rocknix[.]|portareos.|g' \
        -e "s|${guard}|rocknix.org|g"

  # rocknix.org is deliberately preserved above, so it must not count here.
  local left
  left="$(grep -rhoE 'rocknix-[a-z]+|rocknix[.][a-z]+' "${PKG_BUILD}" 2>/dev/null \
          | grep -vx 'rocknix.org' | wc -l)"
  [ "${left}" = "0" ] || die "emulationstation: ${left} ROCKNIX interface references survived the rewrite"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/config/locale
    cp -a ${PKG_BUILD}/locale/lang/* ${INSTALL}/usr/config/locale

    # Pre-generate default (en_US.UTF-8) locale for lower-end devices to speed up first boot
    # This saves a minute or two on RK3326 in a cost of about 1 MB of SYSTEM size
    # Copy-paste of a locale generating part of es_settings script
    I18NPATH=$(get_install_dir glibc)/usr/share/i18n/locales/ \
      localedef --force --verbose --inputfile=en_US --charmap=UTF-8 \
      ${INSTALL}/usr/config/locale/en_US.UTF-8 || true

  mkdir -p ${INSTALL}/usr/config/emulationstation
    cp -a ${PKG_DIR}/config/common/*.cfg ${INSTALL}/usr/config/emulationstation
    rm -f ${INSTALL}/usr/config/emulationstation/resources/logo.png

  mkdir -p ${INSTALL}/usr/config/emulationstation/resources
    cp -a ${PKG_BUILD}/resources/* ${INSTALL}/usr/config/emulationstation/resources

  mkdir -p ${INSTALL}/usr/bin
    cp -a ${PKG_BUILD}/es_settings ${INSTALL}/usr/bin
    cp -a ${PKG_BUILD}/start_es.sh ${INSTALL}/usr/bin
    cp -a ${PKG_BUILD}/serial_number_check ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/bin
    #ln -sf /storage/.config/emulationstation/resources ${INSTALL}/usr/bin/resources
    cp -a ${PKG_BUILD}/emulationstation ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/etc
    ln -sf /storage/.cache/system_timezone ${INSTALL}/etc/timezone

  mkdir -p ${INSTALL}/etc/emulationstation
    ln -sf /storage/.config/emulationstation/themes ${INSTALL}/etc/emulationstation/themes
    ln -sf ${INSTALL}/usr/config/emulationstation/es_systems.cfg ${INSTALL}/etc/emulationstation/es_systems.cfg


  # If we're not an emulation device, ES may still be installed so we need a default config.
  if [[ "${EMULATION_DEVICE}" == "no" || "${BASE_ONLY}" == "true" ]]; then
    cat <<EOF >${INSTALL}/usr/config/emulationstation/es_systems.cfg
<?xml version="1.0" encoding="UTF-8"?>
<systemList>
        <system>
                <name>tools</name>
                <fullname>Tools</fullname>
                <manufacturer>PortareOS</manufacturer>
                <release>2024</release>
                <hardware>system</hardware>
                <path>/storage/.config/modules</path>
                <extension>.sh</extension>
                <command>%ROM%</command>
                <platform>tools</platform>
                <theme>tools</theme>
        </system>
</systemList>
EOF
  fi

  #Delete all vulkan options from es_features when vulkan is not present
  if [ ! "${VULKAN_SUPPORT}" = "yes" ]; then
    xmlstarlet ed --inplace -d '//choice[contains(@name, "vulkan")]' ${INSTALL}/usr/config/emulationstation/es_features.cfg
  fi
}


post_install() {
  mkdir -p ${INSTALL}/usr/share
    ln -sf /storage/.config/locale ${INSTALL}/usr/share/locale

  mkdir -p ${INSTALL}/usr/lib
    ln -sf /usr/share/locale ${INSTALL}/usr/lib/locale

  mkdir -p ${INSTALL}/usr/config/emulationstation
    ln -sf /usr/share/locale  ${INSTALL}/usr/config/emulationstation/locale
}
