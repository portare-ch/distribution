#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

# Movies. mpv is the only player on the device, and it draws straight to the
# panel through Vulkan's VK_KHR_display - no compositor, the same path ARMSX2
# takes. portarelauncher has dropped DRM master by the time this runs.

. /etc/profile

set_kill set "mpv"

VK="--vo=gpu-next --gpu-api=vulkan --gpu-context=displayvk"

# The panel's 119.88 Hz mode, found by its rate rather than assumed to be the
# first. It is 120000/1001 exactly, so film at 24000/1001 is five refreshes
# per frame, 29.97 is four and 59.94 is two - every NTSC rate lands on a whole
# number of refreshes and nothing needs resampling. The panel also has a
# 119.63 Hz mode for PlayStation 240p; Vulkan lists only the preferred one
# today, and picking by rate keeps this right if that ever changes.
MODE=$(/usr/bin/mpv --no-config ${VK} --vulkan-display-mode=help 2>/dev/null |
       sed -n 's/^ *Mode \([0-9]\+\): .*(119\.880 Hz)$/\1/p' | head -n1)
if [ -z "${MODE}" ]; then
  log $0 "no 119.880 Hz mode listed, using the first"
  MODE=0
fi

mkdir -p /storage/.config/mpv/watch_later

# --no-config: what plays a film here is this file and input.conf, not
#   whatever an earlier mpv left in /storage.
# display-resample: mpv times frames against the display rather than the
#   audio clock, which with a whole-number ratio means no judder at all.
# decode.conf: the iris hardware decoder for HD, software below 720p - see
#   that file for the measurements and the green-screen rip that led to it.
# aspect.conf: standard-definition rips that lost their 4:3 flag are shown at
#   4:3, so they fill the panel instead of sitting between black bars.
# sd.conf: scanlines and a sharper scaler for standard definition; SELECT
#   turns the scanlines off.
# quit-watch-later on the back button, so a film resumes where it was left.
exec /usr/bin/mpv --no-config \
  ${VK} --vulkan-display-mode=$((10#${MODE})) \
  --video-sync=display-resample \
  --include=/usr/config/mpv/decode.conf \
  --include=/usr/config/mpv/aspect.conf \
  --include=/usr/config/mpv/sd.conf \
  --ao=pipewire \
  --input-gamepad=yes --input-conf=/usr/config/mpv/input.conf \
  --watch-later-dir=/storage/.config/mpv/watch_later \
  --sub-auto=fuzzy \
  "${1}"
