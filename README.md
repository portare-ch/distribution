<img src="distributions/PortareOS/logos/portareos-logo.png" width=320>

# PortareOS

**A Linux distribution for one handheld: the Retroid Pocket Nova, and its
4:3, 120 Hz OLED panel.**

Home: **[os.portare.org](https://os.portare.org)**

> Black coffee. No milk, no sugar, the right amount of beans.

## What makes it different

Most handheld distributions support dozens of devices, and every setting has
to suit all of them. PortareOS supports exactly one device, so it can make
choices nobody else can:

- **Nothing between the game and the screen.** There is no compositor and no
  desktop. The launcher draws straight to the panel through KMS. PlayStation 2
  and movies render straight to it through Vulkan.
- **A panel timed for the games.** The display runs at exactly 119.88 Hz,
  twice NTSC's 59.94. A 60 Hz game shows every frame for exactly two refreshes
  and a 24 fps film for five, so there is no judder to smooth over. A second
  mode at 119.63 Hz covers PlayStation's 240p rate.
- **One emulator per system.** Each system has one emulator, chosen on
  evidence and tuned for this screen and this pad, not a menu of alternatives
  nobody configured. Super Nintendo is the only exception: bsnes is there
  beside snes9x.
- **Everything else is gone.** No desktop, no media centre, no EmulationStation,
  no Samba. What is left boots straight into a list of your games.

## Features

**Picture and timing**

- 1280×960 at 119.88 Hz. NTSC games and films land on whole refreshes.
- PlayStation on exact 4× integer scaling: 320×240 fills the panel with no
  resampling and no borders.
- Black frame insertion, per system, for motion clarity on the OLED.
- Run-ahead on for software-rendered systems, to take latency out.
- Vulkan everywhere it helps: RetroArch, PlayStation 2 and movies.

**Front-end**

- A text-mode launcher that owns the panel directly. It uses no GPU in the
  menu, and between button presses it only wakes once a minute, for the clock.
- Wi-Fi with multiple saved networks. Switching between home and away is one
  press, and new networks are joined with an on-screen keyboard.
- Bluetooth: scan, pair and connect in one press, and auto-connect for your
  headphones.
- USB networking to a computer.
- Button labels for either printing: Retroid (B/A/X/Y) or PlayStation
  (✕/○/△/□).
- Volume, brightness, battery and clock always in the header.
- Tools: file manager, gamepad tester, PortMaster.

**Systems**

- **Nintendo:** Game Boy and Game Boy Color (Gambatte), Game Boy Advance
  (mGBA), Super Nintendo (snes9x, or bsnes), Nintendo 64 (ParaLLEl N64),
  GameCube and Wii (Dolphin).
- **Sega:** Master System, Game Gear, SG-1000, Mega Drive and Mega CD
  (Genesis Plus GX), 32X (PicoDrive), Dreamcast, Naomi and Atomiswave
  (Flycast).
- **Sony:** PlayStation (SwanStation), PlayStation 2 (ARMSX2), PSP (PPSSPP).
- **Arcade and SNK:** FBNeo for arcade and Neo Geo, NeoCD for Neo Geo CD.
- **Also:** Xbox (xemu), ScummVM, PC ports through PortMaster, Steam through
  FEX-Emu and gamescope, and Moonlight for streaming from a PC.

**Movies and music**

- Movies in mpv, straight to the panel: H.264 and HEVC decoded in hardware,
  pad controls, and every film resumes where you left it.
- Music in gmu.

**Sound**

- PipeWire, and nothing else. PulseAudio is not in the image, and CI fails the
  build if it comes back.
- A 5.3 ms audio quantum, down from the 20 ms this fork inherited.
- Bluetooth audio, HDMI and USB audio.

**Under the hood**

- Mainline Linux 7.2, with the Nova's own set of 89 patches.
- `sched_ext` with `scx_lavd`, a latency-aware scheduler, for frame pacing
  across the big and little cores.
- microSD at UHS-I SDR104, not legacy High Speed.
- RetroArch netplay and RetroAchievements.
- SSH, SFTP, Tailscale, WireGuard and ZeroTier. SSH is off until you turn it on.

## Status

PortareOS is **pre-release**. There are nightly builds and no stable release
yet. What stands between it and a public beta is tracked in the
[beta milestone](https://github.com/portare-ch/portareos/milestone/1). The
biggest item: **suspend does not yet save much power**, because memory never
powers down while asleep ([#62](https://github.com/portare-ch/portareos/issues/62)).

[ROADMAP.md](ROADMAP.md) is where it is going. [BUGS.md](BUGS.md) is what is
known to be broken.

## Installing

PortareOS uses its own boot partition label, so the first image has to be
written to the card as a fresh install. An update over an existing ROCKNIX
installation will not find its boot partition. Updates between PortareOS
builds work normally.

Installation steps are at [os.portare.org](https://os.portare.org).

## Building

```
make docker-SM8550
```

Images are written to `target/`. The build needs a container runtime, roughly
100 GB of disk, and several hours the first time.

## Where it came from

PortareOS began as a fork of [ROCKNIX](https://github.com/ROCKNIX/distribution),
itself a fork of [JELOS](https://github.com/JustEnoughLinuxOS/distribution).
Much of the engineering underneath is theirs, and the credit and the licences
stay with them.

It no longer tracks ROCKNIX. The trees have diverged past the point where
merging is cheaper than rewriting, so upstream updates come in selectively,
one package at a time, through `tools/import-upstream-packages`.

**Please do not raise PortareOS problems with the ROCKNIX maintainers.** For
ROCKNIX itself, go to **[rocknix.org](https://rocknix.org)**.

## A note about AI

Yes, 100% and I plan to keep it that way.

## Licenses

**PortareOS** is a fork of **ROCKNIX**, which is a fork of [JELOS](https://github.com/JustEnoughLinuxOS/distribution). All licenses apply, and credit belongs to the ROCKNIX and JELOS teams.

### ROCKNIX Branding

ROCKNIX branding and images are licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](https://creativecommons.org/licenses/by-nc-sa/4.0/).

You are free to:

- Share: copy and redistribute the material in any medium or format
- Adapt: remix, transform, and build upon the material

Under the following terms:

- Attribution: You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- NonCommercial: You may not use the material for commercial purposes.
- ShareAlike: If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

### ROCKNIX Software

Copyright (C) 2024-present [ROCKNIX](https://github.com/ROCKNIX)

Original software and scripts developed by the ROCKNIX team are licensed under the terms of the [GNU GPL Version 2](https://choosealicense.com/licenses/gpl-2.0/). The full license can be found in this project's licenses folder.

### Bundled Works

All other software is provided under each component's respective license. These licenses can be found in the software sources or in this project's licenses folder. Modifications to bundled software and scripts by the ROCKNIX and JELOS teams are licensed under the terms of the software being modified.

## Credits

Like any Linux distribution, this project is not the work of one person. It is the work of many people all over the world who have developed the open source bits without which this project could not exist. Special thanks to ROCKNIX, JELOS, CoreELEC, LibreELEC, and to developers and contributors across the open source community.

### Patches from pocknix-os

A number of the SM8550 kernel patches carried here were taken from
[pocknix-os](https://github.com/shuuri-labs/pocknix-os) by shuuri-labs, either unchanged
or with only the rebasing needed to fit this tree. Authorship is preserved in each patch
header; the work is theirs, and any mistakes in adapting it are mine.

| Patch | What it does |
| --- | --- |
| `0210`, `0211`, `0212` | microSD at UHS-I SDR104 via the downstream `sdhci-msm` driver, plus the `sdhc_2` rebind in the RP6 device tree. Originally from Armbian PR #9546 (Alex Ling). |
| `1012` | rsinput MCU version handshake on init, so the gamepad survives an unlucky resume (jaewun). |
| `1021` | Expose only the 120Hz mode on the RP6 panel (pocknix). `1022` is this fork's port of it to the Nova panel. |
| `1050` | `edt,retain-power-in-suspend` option for edt-ft5x06 (jaewun). |
| `1051` | Lowest A740 GPU operating point, 124.8 MHz (Thorch contributors). |
