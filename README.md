<img src="distributions/PortareOS/logos/portareos-logo.png" width=320>

# PortareOS

**A minimalist Linux distribution for the Retroid Pocket Nova, built around its
4:3 panel and nothing else.**

Home: **[os.portare.org](https://os.portare.org)**

> Black coffee. No milk, no sugar, the right amount of beans.

## What it is

The Nova has a **1280x960 (4:3) 120Hz panel**. That is an unusual shape for a
modern handheld and an excellent one for almost everything made before
widescreen: the NES, the SNES, the Mega Drive, the arcade boards they were
copying, the first three Sony consoles. PortareOS is a distribution for that
panel and that library, on that one device.

Write the card, copy the games across, and the systems worth playing on this
handheld are already configured — for this screen, this gamepad and this SoC,
rather than for generic defaults averaged over a dozen handhelds.

Everything else comes out. Each thing removed is one less package to build,
one less setting to get wrong, and one less menu entry between a cold device
and a game.

## The rules

**One device.** The Retroid Pocket Nova (SM8550). Not a family, not a
platform. Every other device tree, project and distribution has been deleted
from the source tree rather than left switched off.

**4:3, natively.** Render resolutions, integer scaling and refresh rate are
chosen against 1280x960 and 119.88Hz, not adapted to them afterwards.

**One emulator per system.** A second emulator nobody has configured is a
worse experience one menu-tap away, and it dilutes the per-core tuning that
only ever gets written for the default. SNES keeps both snes9x and bsnes, and
arcade is genuinely hard because romset compatibility varies by core version.
Everywhere else, one.

**Latency before everything except correctness.** Input lag is what Android on
this device is worst at. Frame pacing, the compositor path and the emulator
frame queue are treated as latency problems first and throughput problems
second.

**If it is not retro gaming on this handheld, it is not in the image.** No
media centre, no desktop, no general-purpose Linux. A feature has to earn its
build time.

## Where it came from, and where it is not going

PortareOS began as a fork of [ROCKNIX](https://github.com/ROCKNIX/distribution),
which is itself a fork of [JELOS](https://github.com/JustEnoughLinuxOS/distribution).
Nearly all of the engineering that makes this possible is theirs, and the
credit and the licences stay with them.

**It no longer tracks ROCKNIX.** There is no merge from upstream and there
will not be one. The trees have diverged past the point where rebasing is
cheaper than rewriting. Upstream package updates come in selectively, one at a
time, through `tools/import-upstream-packages`, which maps their paths onto
ours and skips what has been removed here.

That is a deliberate trade. ROCKNIX serves many devices well; this serves one
device narrowly. Individual fixes made here may still be worth offering
upstream on their own. The tree as a whole is not.

**Please do not raise PortareOS problems with the ROCKNIX maintainers.** For
the upstream project, its community and its documentation, go to
**[rocknix.org](https://rocknix.org)** and the
[ROCKNIX Discord](https://discord.gg/seTxckZjJy).

Sources are still fetched from ROCKNIX's `distribution-sources` mirror, and
several components are still built from ROCKNIX repositories. Those are
dependencies, not branding, and they keep their names.

## Built for the panel

* Panel driven at **119.88011988Hz**, exactly twice 59.94Hz, so NTSC-rate
  content lands on an even frame boundary instead of beating against a nominal
  120.
* RetroArch takes its refresh rate from DRM rather than from the compositor,
  which is the only place the exact figure survives.
* A 1280x960 viewport and integer scaling for the systems whose native height
  divides cleanly into 960.
* Black frame insertion, which a 120Hz panel showing 60Hz content can afford.

## Tuned for the device

* Deep suspend enabled.
* microSD at UHS-I SDR104 rather than legacy High Speed.
* Input latency work across the gamepad, compositor and emulator frame queue.
* `sched_ext` with `scx_lavd`, the latency-aware scheduler, for frame pacing
  across the Nova's big.LITTLE layout.

Several of the kernel patches behind these came from
[pocknix-os](https://github.com/shuuri-labs/pocknix-os). See Credits.

## What was taken out

Removing things is most of the work, so it is worth being specific about what
is gone.

**Hardware and distributions.** The other twelve device projects and all their
configuration, patches and quirks. The nine non-ROCKNIX hardware projects
inherited from the LibreELEC lineage. The LEIoT and LibreELEC distributions.
Kodi. The unbuilt addon set. The other SM8550 device trees — the four AYN
boards and the Retroid Pocket 6 top-dpad variant — and the six extra
`config.xml` entries that built them, which also put six device choices and
their recovery twins in the boot menu. What remains beside the Nova's own tree
is the two files it is built from.

**Subsystems.** PulseAudio, sndio, libao and VLC. Wine and the Windows system
it backed. NFS, the Samba client and OpenVPN. Infrared remote and Video4Linux
support — the Nova has no IR receiver, no blaster, no camera and no tuner.
mesa-demos and speedtest-cli.

**Emulators.** aethersx2, cemu, drastic, daedalusx64, bigpemu, touchhle,
skyemu, nanoboyadvance, hatari, vita3k and m8c, dropped for duplicating
something already here, for being 16:9 only, or for simply not being wanted.
The inherited libretro core recipes that were never built went with them.

What ships is thirteen libretro cores under RetroArch, plus a short list of
standalone emulators: ARMSX2, RPCS3, xemu, ScummVM, PortMaster, Moonlight and
Steam.

One thing is deliberately still there: `case ${DEVICE}` branches inside
recipes shared with upstream. They are inert with a single device, and editing
them would conflict on every import.

## PipeWire, and nothing else

Pulse is banned. There is no `pulseaudio` recipe left in the tree, nothing
links libpulse, no pulse daemon is built, and a check in
`validate-pull-request.yml` fails the build if any of it comes back.

Everything reaches PipeWire, though not all by the same road, because that is
decided by what each upstream project supports:

| | reaches PipeWire via |
| --- | --- |
| EmulationStation | libpipewire, native |
| RetroArch, FluidSynth, OpenAL Soft | their own PipeWire backends |
| Flycast, ares, ARMSX2, RPCS3 | SDL2 / SDL3, built with the PipeWire driver and PulseAudio off |
| Dolphin | alsa-lib's `pcm_pipewire`, in process |

The one deliberate exception is `pipewire-pulse`, which stays enabled. Steam
and the games it runs carry their own libpulse in the Steam runtime and cannot
be recompiled, so something has to answer them.

The latency floor came down with it. `default.clock.min-quantum` and the
pulse-compat minimums are pinned at 256 frames, 5.3ms at 48kHz, against the
960 frames (20ms) this fork inherited.

## EmulationStation rewritten for it

[emulationstation-sdl3](https://github.com/portare-ch/emulationstation-sdl3) is
built from a fork, and the name says what the fork is for: it runs on SDL3
rather than SDL2, and it talks to PipeWire directly.

The SDL3 half is not a version bump. SDL3 inverted the return convention of
most of its API — `SDL_Init` and friends return true on success where SDL2
returned zero — so every call site had to be read rather than recompiled. A
missed one is not a compile error, it is a black screen on a device that still
answers SSH.

The PipeWire half replaced `VolumeControl`, which was ALSA and PulseAudio side
by side, wrapped in `__APPLE__` and `WIN32` branches for platforms this will
never run on. It is now one native libpipewire implementation that binds the
default sink through the registry and sets `channelVolumes` directly.

Video playback moved from VLC to libmpv's software render API, and the gettext
translation layer is gone.

## What is kept

Not everything inherited is bloat. Still here, because a handheld that plays
games over a network is still a handheld that plays games:

* Local and remote netplay.
* Scraping and RetroAchievements.
* Bluetooth audio and controllers.
* HDMI audio and video out, and USB audio.
* Syncthing and rclone for save and ROM sync.
* WireGuard, Tailscale and ZeroTier.

## What is next

[ROADMAP.md](ROADMAP.md) is where this is going — suspend that actually
suspends, every emulator configured on arrival, and replacing sway with
something that does not assume a keyboard and a pointer.
[BUGS.md](BUGS.md) is what is known to be broken or unfinished, including the
findings too small or too uncertain to file.
[docs/performance-plan.md](docs/performance-plan.md) is what to try next about
performance, with the tests to tell whether it worked.

**Much of the tree has not been verified on hardware.** It builds and the
changes are internally consistent; whether the Nova behaves with all of them
is a separate question. The roadmap says which parts.

## Building

```
make docker-SM8550
```

Images are written to `target/`. The build wants a container runtime, roughly
100 GB of disk and several hours the first time through.

Two things worth knowing:

* The **Build** workflow takes an `incremental` input. Off, it builds
  everything, which is what scheduled and release builds always do. On, it
  restores per-stage state and skips packages whose recipes have not changed.
* `.github/scripts/check-package-deps.py` checks that every package named in a
  `PKG_DEPENDS_*` line exists, resolving variable-driven lists such as
  `PKG_EMUS` and `LIBRETRO_CORES`. It runs early in CI so a missing package
  fails in seconds rather than part-way through a build.

## Installing

PortareOS uses its own boot partition label, so the first image must be
written to the card as a fresh install. An in-place update over an existing
ROCKNIX installation will not find its boot partition. Updates between
PortareOS builds work normally.

Installation steps are at [os.portare.org](https://os.portare.org).

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
