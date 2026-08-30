<img src="distributions/PortareOS/logos/portareos-logo.png" width=320>

# PortareOS

**PortareOS is a fork of [ROCKNIX](https://github.com/ROCKNIX/distribution), focused exclusively on the Retroid Pocket Nova.**

Home: **os.portare.org** *(not up yet — this repository is the canonical source until it is)*

PortareOS is an immutable Linux distribution for handheld gaming devices, developed by a community of enthusiasts, and is itself a fork of [JELOS](https://github.com/JustEnoughLinuxOS/distribution). All of the work that makes this project possible is theirs; PortareOS only adds a thin layer of device-specific tuning on top.

## What this fork is for

The Nova has a **1280x960 (4:3) 120Hz panel** and sits alongside the Retroid Pocket 6 in PortareOS's SM8550 platform, sharing its device tree and its emulator configuration. That sharing is sensible upstream, but it means a number of defaults are written for the RP6's 1920x1080 16:9 display and land unexamined on the Nova.

This fork exists to correct that, and to carry Nova-specific work that would not make sense upstream:

* Panel and display tuning for 1280x960 — render resolutions, and integer scaling for the systems whose native height divides cleanly into 960.
* Deep suspend enabled and gated for the Nova.
* microSD at UHS-I SDR104 rather than legacy High Speed.
* Input latency work across the gamepad, compositor and emulator frame queue.

Several of the kernel patches behind those come from [pocknix-os](https://github.com/shuuri-labs/pocknix-os) rather than from this fork — see Credits.

Only the **SM8550** platform is built. Support for the other devices is left in the tree untouched, so that changes can still be contributed back upstream where they are useful to everyone.

## Relationship to upstream

This is a personal fork. It tracks `PortareOS/distribution` and merges from it regularly; nothing here is intended to replace or compete with PortareOS. Device-specific changes are deliberately kept in per-device quirks rather than in shared configuration, so that the general fixes among them remain suitable for upstream contribution.

For the upstream project, its community and its documentation, go to **[rocknix.org](https://rocknix.org)** and the [ROCKNIX Discord](https://discord.gg/seTxckZjJy). Please do not raise PortareOS issues with the ROCKNIX maintainers.

## Features

Inherited from PortareOS:

* Integrated cross-device local and remote network play.
* In-game touch support on supported devices.
* Fine grain control for battery life or performance.
* Includes support for playing Music and Video.
* Bluetooth audio and controller support.
* Support for HDMI audio and video out, and USB audio.
* Device to device and device to cloud sync with Syncthing and rclone.
* VPN support with Wireguard, Tailscale, and ZeroTier.
* Includes built-in support for scraping and retroachievements.

## Building

```
make docker-SM8550
```

Images are written to `target/`. See the PortareOS documentation for the full build environment requirements.

## Licenses

**PortareOS** is a fork of **PortareOS**, which is a fork of [JELOS](https://github.com/JustEnoughLinuxOS/distribution). All licenses apply, and credit belongs to the PortareOS and JELOS teams.

You are free to:

- Share: copy and redistribute the material in any medium or format
- Adapt: remix, transform, and build upon the material

Under the following terms:

- Attribution: You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- NonCommercial: You may not use the material for commercial purposes.
- ShareAlike: If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

### PortareOS Software

Copyright (C) 2024-present [ROCKNIX](https://github.com/ROCKNIX)

Original software and scripts developed by PortareOS are licensed under the terms of the [GNU GPL Version 2](https://choosealicense.com/licenses/gpl-2.0/).  The full license can be found in this project's licenses folder.

### Bundled Works

All other software is provided under each component's respective license.  These licenses can be found in the software sources or in this project's licenses folder.  Modifications to bundled software and scripts by the JELOS team are licensed under the terms of the software being modified.

## Credits

Like any Linux distribution, this project is not the work of one person.  It is the work of many people all over the world who have developed the open source bits without which this project could not exist.  Special thanks to PortareOS, CoreELEC, LibreELEC, JELOS, and to developers and contributors across the open source community.

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
