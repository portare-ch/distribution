# What is in the image, and what should not be

An inventory of the packages in the PortareOS image, from the package definitions and checked against a device running build 20260925 (`d3fa9894`): the binaries, libraries and services present, their sizes, and who links what. Sizes are as installed: `/usr/lib` 732 MB, `/usr/share` 457 MB, `/usr/bin` 220 MB, about 1.4 GB in all. Each package is in one of three lists: essential, candidate for removal, questionable.

The rule this applies is the README's: if it is not needed for a smooth game, it is not in the image.

## Essential

| Package | Why |
|---|---|
| linux 7.2.5, linux-firmware, busybox, systemd, util-linux, coreutils, bash, kmod, udev | The base. |
| mesa (turnip, freedreno; `libgallium` 21 MB), vulkan-loader, libdrm, libglvnd | The display. |
| pipewire, wireplumber, alsa-lib, alsa-ucm-conf, alsa-topology-conf | Audio; the 32 / 44.1 / 48 kHz link runs through it. |
| networkmanager, iwd, wireless-regdb, openssh, rsync, bluez | Wi-Fi, SSH, controllers. |
| retroarch, core-info, slang-shaders (trimmed, see below), the 15 cores (193 MB) | The systems. |
| armsx2-sa, xemu-sa (19 MB), scummvmsa (76 MB), ppsspp-lr, moonlight, mpv, ffmpeg, libplacebo, luajit | The standalone systems; mpv's Lua runs our seek script. |
| portarelauncher, portareos, system-utils, quirks, autostart, powerstate, sleep, inputplumber (10 MB) | Our own stack; inputplumber is the gamepad. |
| steam, gamescope, xwayland, seatd, fex-emu, pressure-vessel, the X11 libraries | The one compositor exception, about 35 MB on the image; the runtime lives on `/storage`. |
| retroarch-assets (33 MB) | RetroArch's own menu needs its assets. Trimmable to one menu driver's. |
| e2fsprogs, dosfstools, exfatprogs, ntfs-3g, parted, udevil, umtprd | Cards, drives, USB file transfer. |
| dbus, glib, openssl, gnutls, curl, wget, jq, xmlstarlet | What the scripts use. |

## Candidates for removal

| Package | MB | Why |
|---|---|---|
| **libretro-database** | 172 | RetroArch's scanner and playlist database. The launcher scans folders itself; nothing on the device reads it. The largest single item in the image. |
| **kernel-overlays** | 59 | Every kernel module for every board the base tree knows. The Nova needs a fraction: build in what it uses, drop the rest, through the kernel config. |
| **common-shaders, glsl-shaders, retropie-shaders** | 22+ | GLSL shaders for RetroArch's `gl` driver. We run Vulkan, which takes slang shaders only. |
| **slang-shaders** — trim, not drop | 70 → ~10 | We use `crt/crt-guest-advanced`, `handheld/lcd-grid-v2` and our own `portare/`. Keep those families and what they include; drop the other 60 MB. |
| **retroarch-overlays** | 13 | Touch overlays. Unused. |
| **renderdoc, apitrace (with glretrace, eglretrace), gdb, gdbserver, perf, vulkan-tools, glslc, binutils (strings, readelf), v4l-utils, edid-decode, cec-ctl, plplay, gltrim, wflinfo** | ~55 | Debugging and GPU tracing tools, in a release image. `DEBUG_PACKAGES` is off, so they arrive as somebody's dependency; find whose. |
| **gtk3, gdk-pixbuf, atk, at-spi2-core, the pango tools** | ~12 | Nothing on the device links GTK except GTK's own utilities. |
| **gstreamer, gst-plugins-base, gst-plugins-good, gst-libav** | 8 | No binary links it. |
| **espeak** | 1 | Speech for EmulationStation's accessibility mode. EmulationStation is gone. |
| **entware** (`installentware`, `entware.service`) | 1 | An opkg package manager bootstrap: the definition of an anti-feature here. |
| **usb-modeswitch** | 1 | Switches 3G modems into modem mode. |
| **btop** (htop stays), the sqlite3 CLI, nano and dialog, bluez's btmon, meshctl and mesh-cfgclient, two of p7zip's three binaries | ~6 | Duplicates and unused command-line tools. |
| **xorg.service, xorg-launch-helper, xrandr** | 1 | There is no Xorg on the image, only Xwayland under gamescope. |
| **iwd_get-networks, ukify, spit** | – | Leftover scripts; the launcher uses nmcli. |
| **gconv** — trim to UTF-8 and Latin-1 | 19 | glibc's charset converters for every encoding there is. |
| **i18n** — trim to en_US | 13 | Locales for the world. |
| The 310 `.info` files of cores we do not ship | 1 | Cosmetic; ship the 15 we have. |

## Questionable: replace, or reconsider

| Package | MB | The question |
|---|---|---|
| **qt6** (Core, Gui, Widgets, Quick, Qml, ShaderTools, Designer, …) | ~60 | Only ARMSX2's offscreen Qt UI and FEXConfig use it. ARMSX2 runs the GS on KMS and drags Qt along for a window nobody sees; a Qt-less build, or a headless target, drops the biggest library on the image. FEXConfig is a desktop configuration dialog and has no place on a handheld. |
| **python3** with pyudev, six, pyyaml, setuptools | 34 | Real users: `portareos-bluetooth-agent`, the pairing agent that runs as a service, and Steam's `steamdeps`. Rewrite the agent in C against bluez's D-Bus API, or as a bluetoothctl script, and Python goes. |
| **tailscale** (`tailscaled`, enabled at boot) | 26 | A Go VPN mesh daemon on a handheld, the second-largest binary after ScummVM. Keep if it is used; otherwise out. **zerotier-one** (2 MB) is the same question. |
| **avahi, nss-mdns** | 3 | mDNS. Useful for `portareos.local` over SSH; otherwise off. |
| **fluidsynth, soundfont-generaluser** (30 MB), `fluidsynth.service` | 31 | MIDI for ScummVM. Worth having for ScummVM, but a 30 MB General MIDI soundfont plus a system-wide synth service is a lot: ScummVM can load a soundfont itself, and smaller ones exist. |
| **mangohud, mangoapp** | 12 | A performance overlay: handy for development, an anti-feature for a player. gamescope runs without it. |
| **scummvm** | 76 | A supported system, built with every engine. A build with the engines that matter would halve it. |
| **fbneo** core | 76 | The largest core: every arcade driver. Fine for as long as arcade is a system. |
| **`/usr/lib/compat`**: libavcodec 58, librsvg, x265, aom, openssl 1.1, SDL2 | 41 | Old-ABI libraries for PortMaster ports: a second copy of ffmpeg and friends. Stays exactly as long as PortMaster does. |
| **portmaster** | – | Ports need the compat set above and their own launcher scripts. If ports are not a goal, it and the 41 MB leave together. |
| **umtprd** (MTP) beside the USB network gadget | – | Two USB file-transfer paths where one would do. |
| **btrfs-progs, libtirpc and rpcbind, heimdal, samba's libraries** | ~10 | NFS and Samba are off in the options, but these came along as dependencies of something. Find whose. |

## Services that start at boot and deserve a look

`tailscaled`, `zerotier-one`, `avahi-daemon`, `entware`, `fluidsynth`, `xorg`, `batteryledstatus` (idle unless `led.color=battery`), `hdmi-hotplug` (the Nova has USB-C DisplayPort; keep), `debug-shell`, `debugconfig`.

## The sum

libretro-database 172 + kernel modules ~45 + shaders ~80 + debug tools ~55 + Qt ~60 + Python 34 + tailscale 26 + GTK and GStreamer ~20 + locales and gconv ~25: **about 500 MB of the 1.4 GB installed, a third of the image, without touching a supported system.**

## Method

Package set: a walk of `PKG_DEPENDS_TARGET` from `virtual/image` through `packages/` and `projects/PortareOS/packages/` (project overrides winning), conditionals included. Ground truth: on the device, `ls -S /usr/bin`, `du -sm` over `/usr/lib` and `/usr/share`, `ldd` over every binary in `/usr/bin` to see who links GTK, GStreamer, Python, Qt and X11, the systemd unit list, and `command -v` for the tools in question.
