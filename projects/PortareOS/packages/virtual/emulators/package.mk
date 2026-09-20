# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="emulators"
PKG_LICENSE="GPLv2"
PKG_SITE="https://rocknix.org"
PKG_SECTION="emulation" # Do not change to virtual or makeinstall_target will not execute.
PKG_LONGDESC="Emulation metapackage."
PKG_TOOLCHAIN="manual"

PKG_EMUS="duckstation-sa moonlight mupen64plus-sa ppsspp-sa scummvmsa wine"

EMUS_32BIT=""

PKG_RETROARCH="core-info libretro-database retroarch retroarch-assets retroarch-joypads retroarch-overlays retropie-shaders slang-shaders"

LIBRETRO_CORES="beetle-gba-lr bsnes2014-accuracy-lr bsnes2014-balanced-lr bsnes2014-performance-lr \
                 bsnes-mercury-accuracy-lr bsnes-mercury-balanced-lr bsnes-mercury-performance-lr \
                 beetle-supafaust-lr doublecherrygb-lr fbalpha2012-lr fbalpha2019-lr fbneo-lr flycast-lr \
                 gambatte-lr gearboy-lr gearsystem-lr geolith-lr genesis-plus-gx-lr genesis-plus-gx-wide-lr \
                 mame-lr mame2003-plus-lr mame2010-lr mame2015-lr mesen-s-lr mgba-lr mupen64plus-lr \
                 mupen64plus-nx-lr neocd_lr parallel-n64-lr pcsx_rearmed-lr picodrive-lr sameboy-lr scummvm-lr \
                 skyemu-lr smsplus-gx-lr snes9x-lr snes9x2002-lr snes9x2005_plus-lr snes9x2010-lr supersnes9x-lr \
                 swanstation-lr tgbdual-lr vba-next-lr vbam-lr"

### aarch64 libretro and sa cores
if [ "${ARCH}" = "aarch64" ]; then
  LIBRETRO_CORES+=" duckstation-lr flycast2021-lr ppsspp-lr"
  PKG_EMUS+="box64 portmaster"
fi

### Emulators or cores for specific devices
case "${DEVICE}" in
  H700|RK3326)
    [ "${ENABLE_32BIT}" == "true" ] && EMUS_32BIT="box86 gpsp-lr pcsx_rearmed-lr"
    PKG_DEPENDS_TARGET+=" common-shaders glsl-shaders"
    PKG_EMUS+="mednafen"
    ;;
  RK3399)
    [ "${ENABLE_32BIT}" == "true" ] && EMUS_32BIT="box86 gpsp-lr pcsx_rearmed-lr"
    PKG_EMUS+="mednafen"
    LIBRETRO_CORES+=" beetle-psx-lr bsnes-lr bsnes-hd-lr dolphin-lr"
    ;;
  RK3566|RK3576)
    [ "${ENABLE_32BIT}" == "true" ] && EMUS_32BIT="box86 gpsp-lr pcsx_rearmed-lr"
    PKG_DEPENDS_TARGET+=" common-shaders glsl-shaders"
    PKG_EMUS+="mednafen"
    LIBRETRO_CORES+=" dolphin-lr"
    ;;
  RK3588)
    [ "${ENABLE_32BIT}" == "true" ] && EMUS_32BIT="box86 gpsp-lr pcsx_rearmed-lr"
    PKG_EMUS+="mednafen"
    LIBRETRO_CORES+=" beetle-psx-lr bsnes-lr bsnes-hd-lr dolphin-lr"
    ;;
  SM6115)
    [ "${ENABLE_32BIT}" == "true" ] && EMUS_32BIT="box86 gpsp-lr pcsx_rearmed-lr"
    PKG_EMUS+="mednafen armsx2-sa"
    LIBRETRO_CORES+=" beetle-psx-lr bsnes-lr bsnes-hd-lr dolphin-lr"
    ;;
  SM8250)
    [ "${ENABLE_32BIT}" == "true" ] && EMUS_32BIT="box86 gpsp-lr pcsx_rearmed-lr"
    PKG_EMUS+="mednafen rpcs3-sa xemu-sa steam armsx2-sa"
    LIBRETRO_CORES+=" beetle-psx-lr bsnes-lr bsnes-hd-lr dolphin-lr"
    ;;
  SM8550)
    [ "${ENABLE_32BIT}" == "true" ] && EMUS_32BIT="box86 gpsp-lr pcsx_rearmed-lr"
    PKG_EMUS+="ares-sa gopher64-sa mednafen rpcs3-sa xemu-sa steam armsx2-sa"
    LIBRETRO_CORES+=" beetle-psx-lr bsnes-lr bsnes-hd-lr dolphin-lr"
    ;;
  SM8650|SM8750)
    PKG_EMUS+="ares-sa gopher64-sa mednafen rpcs3-sa xemu-sa steam armsx2-sa"
    LIBRETRO_CORES+=" beetle-psx-lr bsnes-lr bsnes-hd-lr dolphin-lr"
    ;;
  S922X)
    [ "${ENABLE_32BIT}" == "true" ] && EMUS_32BIT="box86 pcsx_rearmed-lr"
    PKG_EMUS+="duckstation-sa armsx2-sa"
    LIBRETRO_CORES+=" beetle-psx-lr bsnes-lr bsnes-hd-lr dolphin-lr"
    ;;
  AMD64)
    PKG_EMUS+="ares-sa gopher64-sa mednafen xemu-sa armsx2-sa"
    LIBRETRO_CORES+=" beetle-psx-lr bsnes-lr bsnes-hd-lr dolphin-lr"
esac

# Split building emulators into 2 stages, needed to fit the jobs into the 6 hour GH runner time limit.
case "${TARGET_TYPE}" in
  cores_only)
    PKG_DEPENDS_TARGET+=" ${LIBRETRO_CORES}"
    ;;
  emus_only)
    PKG_DEPENDS_TARGET+=" ${PKG_EMUS} ${EMUS_32BIT} ${PKG_RETROARCH}"
    ;;
  none)
    ;;
  *)
    PKG_DEPENDS_TARGET+=" ${PKG_EMUS} ${EMUS_32BIT} ${PKG_RETROARCH} ${LIBRETRO_CORES}"
    ;;
esac

install_script() {
  if [ ! -d "${INSTALL}/usr/config/modules" ]; then
    mkdir -p ${INSTALL}/usr/config/modules
  fi
  cp -rf ${PKG_DIR}/sources/"${1}" ${INSTALL}/usr/config/modules
  chmod 0755 ${INSTALL}/usr/config/modules/"${1}"
}

makeinstall_target() {
  ### README BEFORE EDITING
  ###
  ### is now automatically generated when this package is built.
  ###
  ### system is generated and added to ES the cores need to already be defined.
  ###
  ### will result in a build failure.
  ###
  ### add_emu_core schema:
  ###
  ### 3do      retroarch  opera  true
  ###

  ### Flush cache from previous builds
  clean_es_cache
  clean_doc_cache

  ### Add bezels directory
  add_system_dir /storage/roms/bezels

  ### Add BIOS directory
  add_system_dir /storage/roms/bios

  ### Add music directory
  add_system_dir /storage/roms/music

  ### Add save states directory
  add_system_dir /storage/roms/savestates

  ### Add themes directory
  add_system_dir /storage/roms/themes

  ### Apply documentation header
  start_system_doc

  ### Arcade
  add_emu_core arcade retroarch mame2003_plus true
  add_emu_core arcade retroarch mame2010 false
  add_emu_core arcade retroarch mame2015 false
  add_emu_core arcade retroarch fbneo false
  add_emu_core arcade retroarch fbalpha2012 false
  add_emu_core arcade retroarch fbalpha2019 false
  add_emu_core arcade retroarch mame false
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core arcade ares ares-sa false
      ;;
  esac
  add_es_system arcade

  ### Atari 7800

  ## Atari 800

  ## Atari ST

  ## Sammy Atomiswave
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115)
      add_emu_core atomiswave retroarch flycast2021 true
      add_emu_core atomiswave retroarch flycast false
      ;;
    SM8250|SM8550|SM8650|SM8750|S922X)
      add_emu_core atomiswave retroarch flycast true
      add_emu_core atomiswave retroarch flycast2021 false
      ;;
    AMD64)
      add_emu_core atomiswave retroarch flycast true
      ;;
    *)
      add_emu_core atomiswave retroarch flycast true
      ;;
  esac
  add_es_system atomiswave

  ### Capcom Playsystem 1
  add_emu_core cps1 retroarch fbneo true
  add_emu_core cps1 retroarch mame2003_plus false
  add_emu_core cps1 retroarch mame2010 false
  add_emu_core cps1 retroarch fbalpha2012 false
  add_emu_core cps1 AdvanceMame AdvanceMame false
  add_es_system cps1

  ### Capcom Playsystem 2
  add_emu_core cps2 retroarch fbneo true
  add_emu_core cps2 retroarch mame2003_plus false
  add_emu_core cps2 retroarch mame2010 false
  add_emu_core cps2 retroarch fbalpha2012 false
  add_emu_core cps2 AdvanceMame AdvanceMame false
  add_es_system cps2

  ### Capcom Playsystem 3
  add_emu_core cps3 retroarch fbneo true
  add_emu_core cps3 retroarch mame2003_plus false
  add_emu_core cps3 retroarch mame2010 false
  add_emu_core cps3 retroarch fbalpha2012 false
  add_emu_core cps3 AdvanceMame AdvanceMame false
  add_es_system cps3

  ### Sega Dreamcast
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115)
      add_emu_core dreamcast retroarch flycast2021 true
      add_emu_core dreamcast retroarch flycast false
      ;;
    SM8250|SM8550|SM8650|SM8750|S922X)
      add_emu_core dreamcast retroarch flycast true
      add_emu_core dreamcast retroarch flycast2021 false
      ;;
    AMD64)
      add_emu_core dreamcast retroarch flycast true
      ;;
    *)
      add_emu_core dreamcast retroarch flycast true
      ;;
  esac
  add_es_system dreamcast

  ### Final Burn Neo
  add_emu_core fbn retroarch fbneo true
  add_emu_core fbn retroarch mame2003_plus false
  add_emu_core fbn retroarch mame2010 false
  add_emu_core fbn retroarch mame2015 false
  add_emu_core fbn retroarch mame false
  add_emu_core fbn retroarch fbalpha2012 false
  add_emu_core fbn retroarch fbalpha2019 false
  add_es_system fbn

  ### Nintendo GameBoy
  add_emu_core gb retroarch gambatte true
  add_emu_core gb retroarch sameboy false
  add_emu_core gb retroarch gearboy false
  add_emu_core gb retroarch tgbdual false
  add_emu_core gb retroarch mgba false
  add_emu_core gb retroarch vbam false
  add_emu_core gb retroarch DoubleCherryGB false
  add_emu_core gb retroarch skyemu false
  add_emu_core gb retroarch mesen-s false
  add_emu_core gb retroarch supersnes9x false
  case ${DEVICE} in
    RK3399|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|S922X|AMD64)
      add_emu_core gb retroarch bsnes false
      ;;
  esac
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core gb mednafen gb false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core gb ares ares-sa false
      ;;
  esac
  add_es_system gb

  ### Nintendo GameBoy Hacks
  add_emu_core gbh retroarch gambatte true
  add_emu_core gbh retroarch sameboy false
  add_emu_core gbh retroarch gearboy false
  add_emu_core gbh retroarch tgbdual false
  add_emu_core gbh retroarch mgba false
  add_emu_core gbh retroarch vbam false
  add_emu_core gbh retroarch DoubleCherryGB false
  add_emu_core gbh retroarch skyemu false
  add_emu_core gbh retroarch mesen-s false
  add_emu_core gbh retroarch supersnes9x false
  case ${DEVICE} in
    RK3399|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|S922X|AMD64)
      add_emu_core gbh retroarch bsnes false
      ;;
  esac
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core gbh mednafen gb false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core gbh ares ares-sa false
      ;;
  esac
  add_es_system gbh

  ### Nintendo GameBoy Advance
  add_emu_core gba retroarch mgba true
  add_emu_core gba retroarch vbam false
  add_emu_core gba retroarch vba_next false
  add_emu_core gba retroarch beetle_gba false
  add_emu_core gba retroarch skyemu false
  case ${DEVICE} in
    H700|RK3326|RK3576|RK3566|S922X)
      add_emu_core gba retroarch gpsp false
      ;;
    RK3399|RK3588|SM6115|SM8250|SM8550)
      add_emu_core gba retroarch gpsp false
      ;;
    SM8650|SM8750|AMD64)
      ;;
  esac
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core gba mednafen gba false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core gba ares ares-sa false
      ;;
  esac
  add_es_system gba

  ### Nintendo GameBoy Advance Hacks
  add_emu_core gbah retroarch mgba true
  add_emu_core gbah retroarch vbam false
  add_emu_core gbah retroarch vba_next false
  add_emu_core gbah retroarch beetle_gba false
  add_emu_core gbah retroarch skyemu false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550)
      add_emu_core gbah retroarch gpsp false
      add_emu_core gbah mednafen gba false
      ;;
    SM8650|SM8750|AMD64)
      add_emu_core gbah mednafen gba false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core gbah ares ares-sa false
      ;;
  esac
  add_es_system gbah

  ### Nintendo GameBoy Advance Video
  add_emu_core gbav retroarch mgba true
  add_emu_core gbav retroarch vbam false
  add_emu_core gbav retroarch vba_next false
  add_emu_core gbav retroarch beetle_gba false
  add_emu_core gbav retroarch skyemu false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550)
      add_emu_core gbav retroarch gpsp false
      add_emu_core gbav mednafen gba false
      ;;
    SM8650|SM8750|AMD64)
      add_emu_core gbav mednafen gba false
      ;;
  esac
  add_es_system gbav

  ### Nintendo GameBoy Color
  add_emu_core gbc retroarch gambatte true
  add_emu_core gbc retroarch sameboy false
  add_emu_core gbc retroarch gearboy false
  add_emu_core gbc retroarch tgbdual false
  add_emu_core gbc retroarch mgba false
  add_emu_core gbc retroarch vbam false
  add_emu_core gbc retroarch DoubleCherryGB false
  add_emu_core gbc retroarch skyemu false
  add_emu_core gbc retroarch mesen-s false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core gbc mednafen gb false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core gbc ares ares-sa false
      ;;
  esac
  add_es_system gbc

  ### Nintendo GameBoy Color Hacks
  add_emu_core gbch retroarch gambatte true
  add_emu_core gbch retroarch sameboy false
  add_emu_core gbch retroarch gearboy false
  add_emu_core gbch retroarch tgbdual false
  add_emu_core gbch retroarch mgba false
  add_emu_core gbch retroarch vbam false
  add_emu_core gbch retroarch DoubleCherryGB false
  add_emu_core gbch retroarch skyemu false
  add_emu_core gbch retroarch mesen-s false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core gbch mednafen gb false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core gbch ares ares-sa false
      ;;
  esac
  add_es_system gbch

  ### Nintendo GameCube
  case ${DEVICE} in
    RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|S922X|AMD64)
      add_emu_core gamecube retroarch dolphin true
      add_es_system gamecube
      ;;
  esac

  ### Nintendo Triforce
  case ${DEVICE} in
    RK3399|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core triforce retroarch dolphin true
      add_es_system triforce
      ;;
  esac

  ### Nintendo Wii/ware
  case ${DEVICE} in
    RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|S922X|AMD64)
      add_emu_core wii retroarch dolphin true
      add_emu_core wiiware retroarch dolphin true
      add_es_system wii
      add_es_system wiiware
      ;;
  esac

  ### Sega GameGear
  add_emu_core gamegear retroarch gearsystem true
  add_emu_core gamegear retroarch genesis_plus_gx false
  add_emu_core gamegear retroarch picodrive false
  add_emu_core gamegear retroarch smsplus false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core gamegear mednafen gg false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core gamegear ares ares-sa false
      ;;
  esac
  add_es_system gamegear

  ### Sega GameGear Hacks
  add_emu_core ggh retroarch gearsystem true
  add_emu_core ggh retroarch genesis_plus_gx false
  add_emu_core ggh retroarch picodrive false
  add_emu_core ggh retroarch smsplus false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core ggh mednafen gg false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core ggh ares ares-sa false
      ;;
  esac
  add_es_system ggh

  ## Steam & Heroic Games Launcher
  case ${DEVICE} in
    SM8250|SM8550|SM8650|SM8750)
      add_emu_core steam steam steam true
      install_script "Install Steam.sh"
      install_script "Uninstall Steam.sh"
      add_es_system steam
      ;;
  esac

  ### Arcade (MAME)
  add_emu_core mame retroarch mame2003_plus true
  add_emu_core mame retroarch mame2010 false
  add_emu_core mame retroarch mame2015 false
  add_emu_core mame retroarch mame false
  add_emu_core mame retroarch fbneo false
  add_emu_core mame retroarch fbalpha2012 false
  add_emu_core mame retroarch fbalpha2019 false
  add_es_system mame

  ### Sega MegaDrive
  add_emu_core megadrive-japan retroarch genesis_plus_gx true
  add_emu_core megadrive-japan retroarch genesis_plus_gx_wide false
  add_emu_core megadrive-japan retroarch picodrive false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core megadrive-japan mednafen md false
      ;;
  esac
  add_es_system megadrive-japan

  ### Nintendo MSU-1
  add_emu_core snesmsu1 retroarch snes9x true
  add_emu_core snesmsu1 retroarch supersnes9x false
  add_emu_core snesmsu1 retroarch beetle_supafaust false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core snesmsu1 mednafen snes_faust false
      ;;
  esac
  add_es_system snesmsu1

  ### Sega Naomi
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115)
      add_emu_core naomi retroarch flycast2021 true
      add_emu_core naomi retroarch flycast false
      ;;
    SM8250|SM8550|SM8650|SM8750|S922X)
      add_emu_core naomi retroarch flycast true
      add_emu_core naomi retroarch flycast2021 false
      ;;
    AMD64)
      add_emu_core naomi retroarch flycast true
      ;;
    *)
      add_emu_core naomi retroarch flycast true
      ;;
  esac
  add_es_system naomi

  ### SNK NeoGeo
  add_emu_core neogeo retroarch fbneo true
  add_emu_core neogeo retroarch mame2003_plus false
  add_emu_core neogeo retroarch fbalpha2012 false
  add_emu_core neogeo retroarch fbalpha2019 false
  add_emu_core neogeo retroarch mame2010 false
  add_emu_core neogeo retroarch mame2015 false
  add_emu_core neogeo retroarch mame false
  add_emu_core neogeo retroarch geolith false
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core neogeo ares ares-sa false
      ;;
  esac

  add_es_system neogeo

  ### SNK NeoCD
  add_emu_core neocd retroarch neocd true
  add_emu_core neocd retroarch fbneo false
  add_emu_core neocd retroarch geolith false
  add_es_system neocd

  ### Nintendo 64
  add_emu_core n64 retroarch mupen64plus_next true
  if [ "${PREFER_GLES}" = "yes" ]; then
    # This core only has gles renderer
    add_emu_core n64 retroarch mupen64plus false
  fi
  add_emu_core n64 retroarch parallel_n64 false
  add_emu_core n64 mupen64plus mupen64plus-sa false
  case ${DEVICE} in
    SM8550)
      add_emu_core n64 gopher64 gopher64-sa false
      add_emu_core n64 ares ares-sa false
      ;;
    SM8650|SM8750|AMD64)
      add_emu_core n64 gopher64 gopher64-sa false
      add_emu_core n64 ares ares-sa false
      ;;
  esac
  add_es_system n64

  ### Nintendo 64 Disk Drive
  add_emu_core n64dd retroarch mupen64plus_next true
  add_emu_core n64dd retroarch parallel_n64 false
  add_emu_core n64dd mupen64plus mupen64plus-sa false
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core n64dd ares ares-sa false
      ;;
  esac
  add_es_system n64dd

  ### Sony Playstation
  case ${DEVICE} in
    H700|RK3326)
      add_emu_core psx retroarch pcsx_rearmed32 true
      add_emu_core psx retroarch pcsx_rearmed false
      add_emu_core psx retroarch duckstation false
      ;;
    RK3399|RK3588|SM6115)
      add_emu_core psx retroarch pcsx_rearmed true
      add_emu_core psx retroarch pcsx_rearmed32 false
      add_emu_core psx retroarch beetle_psx false
      add_emu_core psx mednafen psx false
      add_emu_core psx retroarch duckstation false
      ;;
    RK3576|RK3566)
      add_emu_core psx retroarch pcsx_rearmed32 true
      add_emu_core psx retroarch pcsx_rearmed false
      add_emu_core psx retroarch duckstation false
      ;;
    SM8250|SM8550)
      add_emu_core psx retroarch pcsx_rearmed32 true
      add_emu_core psx retroarch pcsx_rearmed false
      add_emu_core psx retroarch beetle_psx false
      add_emu_core psx mednafen psx false
     add_emu_core psx retroarch duckstation false
      ;;
    SM8650|SM8750)
      add_emu_core psx retroarch pcsx_rearmed true
      add_emu_core psx retroarch beetle_psx false
      add_emu_core psx mednafen psx false
     add_emu_core psx retroarch duckstation false
      ;;
    S922X)
      add_emu_core psx retroarch pcsx_rearmed true
      add_emu_core psx retroarch beetle_psx false
      add_emu_core psx retroarch duckstation false
      ;;
    AMD64)
      add_emu_core psx retroarch pcsx_rearmed true
      add_emu_core psx retroarch beetle_psx false
      add_emu_core psx mednafen psx false
  esac
  add_emu_core psx duckstation duckstation-sa false
  add_emu_core psx retroarch swanstation false
  add_es_system psx

  ### Sony Playstation 2
  # The RK boards carried aethersx2 and nothing else, so they lose PS2 with it.
  case ${DEVICE} in
  AMD64|S922X|SM6115|SM8250|SM8550|SM8650|SM8750)
    add_emu_core ps2 armsx2 armsx2-sa true
    install_script "Start ARMSX2.sh"
    add_es_system ps2
    ;;
  esac

  ### Sony Playstation 3
  case ${DEVICE} in
    SM8250|SM8550|SM8650|SM8750)
      add_emu_core ps3 rpcs3 rpcs3-sa true
      add_es_system ps3
      install_script "Start RPCS3.sh"
      ;;
  esac

  ### Sony Playstation Portable
  add_emu_core psp ppsspp ppsspp-sa true
  add_emu_core psp retroarch ppsspp false
  add_es_system psp
  install_script "Start PPSSPP.sh"

  ### Sony Playstation Portable Minis
  add_emu_core pspminis ppsspp ppsspp-sa true
  add_emu_core pspminis retroarch ppsspp false
  add_es_system pspminis

  ### ScummVM
  add_emu_core scummvm scummvmsa scummvm true
  add_emu_core scummvm retroarch scummvm false
  add_es_system scummvm
  add_system_dir /storage/roms/scummvm
  install_script "Scan ScummVM Games.sh"
  install_script "Start ScummVM.sh"

  ### Sega 32X
  add_emu_core sega32x retroarch picodrive true
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core sega32x ares ares-sa false
      ;;
  esac
  add_es_system sega32x

  ### Sega CD
  add_emu_core segacd retroarch genesis_plus_gx true
  add_emu_core segacd retroarch picodrive false
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core segacd ares ares-sa false
      ;;
  esac
  add_es_system segacd

  ### Sega Mega-CD
  add_emu_core megacd retroarch genesis_plus_gx true
  add_emu_core megacd retroarch picodrive false
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core megacd ares ares-sa false
      ;;
  esac
  add_es_system megacd

  ### Sega Genesis
  add_emu_core genesis retroarch genesis_plus_gx true
  add_emu_core genesis retroarch genesis_plus_gx_wide false
  add_emu_core genesis retroarch picodrive false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core genesis mednafen md false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core genesis ares ares-sa false
      ;;
  esac
  add_es_system genesis

  ### Sega Genesis Hacks
  add_emu_core genh retroarch genesis_plus_gx true
  add_emu_core genh retroarch genesis_plus_gx_wide false
  add_emu_core genh retroarch picodrive false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core genh mednafen md false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core genh ares ares-sa false
      ;;
  esac
  add_es_system genh

  ### Sega MasterSystem
  add_emu_core mastersystem retroarch gearsystem true
  add_emu_core mastersystem retroarch genesis_plus_gx false
  add_emu_core mastersystem retroarch picodrive false
  add_emu_core mastersystem retroarch smsplus false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core mastersystem mednafen sms false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core mastersystem ares ares-sa false
      ;;
  esac
  add_es_system mastersystem

  ### Sega MegaDrive
  add_emu_core megadrive retroarch genesis_plus_gx true
  add_emu_core megadrive retroarch genesis_plus_gx_wide false
  add_emu_core megadrive retroarch picodrive false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core megadrive mednafen md false
      ;;
  esac
  add_es_system megadrive

  ### Sega MegaDrive Hacks
  add_emu_core megadriveh retroarch genesis_plus_gx true
  add_emu_core megadriveh retroarch genesis_plus_gx_wide false
  add_emu_core megadriveh retroarch picodrive false
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core megadriveh mednafen md false
      ;;
  esac
  add_es_system megadriveh

  ### Sega SG-1000
  add_emu_core sg-1000 retroarch gearsystem true
  add_emu_core sg-1000 retroarch genesis_plus_gx false
  add_emu_core sg-1000 retroarch picodrive false
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core sg-1000 ares ares-sa false
      ;;
  esac
  add_es_system sg-1000

  ### Microsoft XBox
  case ${DEVICE} in
    SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core xbox xemu xemu-sa true
      add_es_system xbox
      install_script "Start Xemu.sh"
      ;;
  esac

  ### Nintendo SNES
  add_emu_core snes retroarch snes9x true
  add_emu_core snes retroarch snes9x2010 false
  add_emu_core snes retroarch snes9x2002 false
  add_emu_core snes retroarch snes9x2005_plus false
  add_emu_core snes retroarch supersnes9x false
  add_emu_core snes retroarch beetle_supafaust false
  add_emu_core snes retroarch bsnes_mercury_accuracy false
  add_emu_core snes retroarch bsnes_mercury_balanced false
  add_emu_core snes retroarch bsnes_mercury_performance false
  add_emu_core snes retroarch bsnes2014_accuracy false
  add_emu_core snes retroarch bsnes2014_balanced false
  add_emu_core snes retroarch bsnes2014_performance false
  add_emu_core snes retroarch mesen-s false
  case ${DEVICE} in
    RK3399|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|S922X|AMD64)
      add_emu_core snes retroarch bsnes false
      add_emu_core snes retroarch bsnes_hd_beta false
      ;;
  esac
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core snes mednafen snes_faust false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core snes ares ares-sa false
      ;;
  esac
  add_es_system snes

  ### Nintendo SNES Hacks
  add_emu_core snesh retroarch snes9x true
  add_emu_core snesh retroarch snes9x2010 false
  add_emu_core snesh retroarch snes9x2002 false
  add_emu_core snesh retroarch snes9x2005_plus false
  add_emu_core snesh retroarch supersnes9x false
  add_emu_core snesh retroarch beetle_supafaust false
  add_emu_core snesh retroarch bsnes_mercury_accuracy false
  add_emu_core snesh retroarch bsnes_mercury_balanced false
  add_emu_core snesh retroarch bsnes_mercury_performance false
  add_emu_core snesh retroarch bsnes2014_accuracy false
  add_emu_core snesh retroarch bsnes2014_balanced false
  add_emu_core snesh retroarch bsnes2014_performance false
  add_emu_core snesh retroarch mesen-s false
  case ${DEVICE} in
    RK3399|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|S922X|AMD64)
      add_emu_core snesh retroarch bsnes false
      add_emu_core snesh retroarch bsnes_hd_beta false
      ;;
  esac
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core snesh mednafen snes_faust false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core snesh ares ares-sa false
      ;;
  esac
  add_es_system snesh

  ### Nintendo Super Famicom
  add_emu_core sfc retroarch snes9x true
  add_emu_core sfc retroarch snes9x2010 false
  add_emu_core sfc retroarch snes9x2002 false
  add_emu_core sfc retroarch snes9x2005_plus false
  add_emu_core sfc retroarch supersnes9x false
  add_emu_core sfc retroarch beetle_supafaust false
  add_emu_core sfc retroarch bsnes_mercury_accuracy false
  add_emu_core sfc retroarch bsnes_mercury_balanced false
  add_emu_core sfc retroarch bsnes_mercury_performance false
  add_emu_core sfc retroarch bsnes2014_accuracy false
  add_emu_core sfc retroarch bsnes2014_balanced false
  add_emu_core sfc retroarch bsnes2014_performance false
  add_emu_core sfc retroarch mesen-s false
  case ${DEVICE} in
    RK3399|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|S922X|AMD64)
      add_emu_core sfc retroarch bsnes false
      add_emu_core sfc retroarch bsnes_hd_beta false
      ;;
  esac
  case ${DEVICE} in
    H700|RK3326|RK3399|RK3576|RK3566|RK3588|SM6115|SM8250|SM8550|SM8650|SM8750|AMD64)
      add_emu_core sfc mednafen snes_faust false
      ;;
  esac
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core sfc ares ares-sa false
      ;;
  esac
  add_es_system sfc

  ### Nintendo Stellaview
  add_emu_core satellaview retroarch snes9x true
  add_emu_core satellaview retroarch snes9x2010 false
  add_emu_core satellaview retroarch snes9x2002 false
  add_emu_core satellaview retroarch snes9x2005_plus false
  add_emu_core satellaview retroarch supersnes9x false
  add_emu_core satellaview retroarch mesen-s false
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core satellaview ares ares-sa false
      ;;
  esac
  add_es_system satellaview

  ### Bandai SuFami Turbo
  add_emu_core sufami retroarch snes9x true
  add_emu_core sufami retroarch supersnes9x false
  case ${DEVICE} in
    SM8550|SM8650|SM8750|AMD64)
      add_emu_core sufami ares ares-sa false
      ;;
  esac
  add_es_system sufami

  ### GamePark GP32
  add_emu_core gp32 retroarch mame true
  add_es_system gp32

  ### PC Ports
  add_emu_core ports portmaster portmaster true
  add_es_system ports

  ### Windows
  add_emu_core windows wine wine true
  add_es_system windows

  ### Media Player
  add_emu_core mplayer mplayer mplayer true
  # Note - there is actually no ffmpeg core, it is compiled into retroarch
  add_emu_core mplayer retroarch ffmpeg false
  add_es_system mplayer

  ### Music Player
  add_emu_core music gmu gmu true
  add_es_system music

  ### Moonlight
  add_emu_core moonlight moonlight moonlight true
  add_es_system moonlight

  ### Tools
  add_es_system tools

  ### Screenshots
  add_es_system imageviewer

  ### Create es_systems
  mk_es_systems

  ### Generate document
  mk_system_doc

  mkdir -p ${INSTALL}/usr/config/emulationstation
  cp -f ${ESTMP}/es_systems.cfg ${INSTALL}/usr/config/emulationstation

  if [ "${WINDOWMANAGER}" = "swaywm-env" ]; then
    sed -i 's~%RUNCOMMAND%~/usr/bin/foot %ROM%~g' ${INSTALL}/usr/config/emulationstation/es_systems.cfg
  else
    sed -i 's~%RUNCOMMAND%~/usr/bin/run %ROM%~g' ${INSTALL}/usr/config/emulationstation/es_systems.cfg
  fi

  ### Automount should handle this.
  cp -f ${ESTMP}/system-dirs.conf ${INSTALL}/usr/config

  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/scripts/mkcontroller ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/lib/autostart/common
  cp ${PKG_DIR}/autostart/* ${INSTALL}/usr/lib/autostart/common
  chmod 0755 ${INSTALL}/usr/lib/autostart/common/*
}
