#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

source /etc/profile

# ARMSX2's own menus, for settings that apply to every game. The SDL
# frontend takes the panel through VK_KHR_display when no compositor is
# there, and with no game named it comes up in its menus.

#Check if ARMSX2 exists in .config
if [ ! -d "/storage/.config/ARMSX2" ]; then
    mkdir -p "/storage/.config/ARMSX2"
        cp -r "/usr/config/ARMSX2" "/storage/.config/"
fi

#Make ARMSX2 bios folder
if [ ! -d "/storage/roms/bios/armsx2" ]; then
    mkdir -p "/storage/roms/bios/armsx2"
fi

set_kill set "armsx2-sdl"
unset WAYLAND_DISPLAY
export SDL_AUDIODRIVER=pipewire

/usr/share/armsx2-sa/armsx2-sdl >/dev/null 2>&1
