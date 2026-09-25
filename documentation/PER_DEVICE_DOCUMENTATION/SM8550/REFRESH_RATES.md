# Refresh and audio rates on the Retroid Pocket Nova (SM8550)

The panel has no variable refresh rate. It runs at **119.880120 Hz**, twice NTSC's 59.94 Hz. For systems whose native rate is noticeably different, `setsettings.sh` (`set_ra_refresh_rate`) asks for a panel mode at exactly twice that rate, and RetroArch switches to it when the game starts.

Where each system's native rate comes from, crystal by crystal, and where an emulator's number differs from the console's, is derived in [CONSOLE_CLOCKS.md](../../CONSOLE_CLOCKS.md). Which systems have their mode, and which are still open, is in [PortareOS_Modelines.md](../../PortareOS_Modelines.md).

Every mode uses the same 1302 × 1001 total timings and changes only the pixel clock. That keeps the panel in its 120 Hz class. The modes are defined in the panel driver, `projects/PortareOS/devices/SM8550/patches/linux/0105-drm-panel-Add-Retroid-Pocket-Nova-panel.patch`.

| Panel mode | Pixel clock | Used by |
|---|---|---|
| 119.880120 Hz | 156240 kHz | default (launcher, everything else) |
| 119.455046 Hz | 155686 kHz | `gambatte`, `mgba` |
| 120.197775 Hz | 156654 kHz | `snes9x`, `bsnes`, `nestopia` |
| 119.652237 Hz | 155943 kHz | `parallel_n64`, `swanstation`, `mednafen_saturn` |
| 119.845592 Hz | 156195 kHz | `genesis_plus_gx` |
| 118.360134 Hz | 154259 kHz | `fbneo`, for `neogeo` only |
| 119.199541 Hz | 155353 kHz | `neocd` |

## Systems

The rates are the original NTSC hardware's frame rate, or for handhelds the hardware's own rate.

Where an emulator runs at a different rate from the hardware, the table says so. On the N64, the hardware rate follows from the video chip's 48.681812 MHz clock: a 3094-clock line and a 263-line frame in 240p, or 262.5 lines in 480i. ParaLLEl N64 as shipped upstream does not emulate the line length: it derives the frame period from a nominal 60 Hz and the frame height the game sets, so it runs at about 60.02 Hz. PortareOS patches it (`003-vi-frame-period-from-h-sync.patch`) to take the period from the `V_SYNC` and `H_SYNC` registers, which gives the console's 59.826 Hz, and matches a panel mode to it.

The PlayStation's line is 3412.5 GPU clocks, the broadcast line. SwanStation rounds it to 3413 and so runs at 59.8173 Hz; PortareOS patches it (`001-ntsc-line-is-3412-5-ticks.patch`) to alternate 3413 and 3412 like the console, which gives 59.826 Hz, the same as the N64, so the two share a mode. SwanStation keeps 263 lines in 480i as well, where the console has 262.5, so a 480i game runs at 59.826 rather than the console's 59.94: 0.19 % slow, the same compromise as the N64's.

| Systems (default emulator) | Native rate (Hz) | Panel mode (Hz) |
|---|---|---|
| gb, gbh, gbc, gbch (Gambatte) | 59.7275 | 119.455 |
| gba, gbah, gbav (mGBA) | 59.7275 | 119.455 |
| snes, snesh, sfc, satellaview, sufami, snesmsu1 (Snes9x) | 60.0988 | 120.198 |
| nes, famicom, fds (Nestopia) | 60.0988 | 120.198 |
| psx (SwanStation) | 59.826 (480i too, see above) | 119.652 |
| saturn (Beetle Saturn) | 59.826 (the core reports it exactly with our patch; in 480i the emulated fields alternate 262 and 263 lines, the reported rate stays) | 119.652 |
| mastersystem, sg-1000, gamegear, ggh (Genesis Plus GX) | 59.9227 | 119.846 |
| megadrive, megadrive-japan, megadriveh, genesis, genh (Genesis Plus GX) | 59.9227 | 119.846 |
| segacd, megacd (Genesis Plus GX) | 59.9227 | 119.846 |
| sega32x (PicoDrive) | 59.9227 (the emulator reports 60) | 119.880 |
| n64, n64dd (ParaLLEl N64) | 59.826 in 240p, 59.94 in 480i | 119.652 |
| neogeo (FBNeo) | 59.1856 (the emulator keeps hundredths: 59.18) | 118.360 |
| neocd (NeoCD) | 59.5999 (the CD's 24.168 MHz crystal) | 119.200 |
| arcade (FBNeo) | depends on the game's board (about 54–61) | 119.880 |
| dreamcast, naomi, atomiswave (Flycast) | 59.94 | 119.880 (exactly 2×) |
| gamecube, triforce, wii, wiiware (Dolphin) | 59.94 | 119.880 (exactly 2×) |
| ps2 (ARMSX2) | 59.94 | 119.880 (exactly 2×) |
| xbox (xemu) | 59.94 | 119.880 (exactly 2×) |
| psp, pspminis (PPSSPP) | 59.94 | 119.880 (exactly 2×) |
| scummvm, steam, ports | no fixed rate (PC games) | 119.880 |
| movies (mpv) | the video's frame rate (23.976, 25, 29.97 …) | 119.880; mpv syncs video to audio |
| music, moonlight, tools, imageviewer | – | 119.880 |

## Audio

The Nova's speaker and headphone link runs at **48 kHz, 44.1 kHz or 32 kHz**. Three things had to allow that: the AudioReach topology blob, which caps the playback PCMs at 48 kHz until `extra-firmware`'s `tplg-playback-rates.py` widens it; kernel patches 1052–1055, which open the DSP ports and the machine driver's fixup to 44.1 and 32 kHz; and the I2S bit clock, which follows the stream (1054). PipeWire allows all three rates (`default.clock.allowed-rates = [ 48000 44100 32000 ]`). [AUDIO_SAMPLE_RATES.md](AUDIO_SAMPLE_RATES.md) describes the whole procedure, for carrying it to another distribution. No rate is a resampling stage in itself: the link switches to the rate of the stream that opens it.

**RetroArch outputs 48 kHz** (`audio_out_rate = 48000`), except for the cores that produce 44.1 kHz: SwanStation, Flycast, PPSSPP, NeoCD, Genesis Plus GX and PicoDrive. Their per-core configs (`config/<core>/<core>.cfg`) ask for 44.1 kHz. Snes9x asks for 32 kHz, and its games in `snesmsu1` for 44.1 kHz (`config/Snes9x/snesmsu1.cfg`, a content-directory override), because MSU-1 games output 44.1 kHz. RetroArch resamples each core's audio to that rate with its sinc resampler, and dynamic rate control keeps the stream in step with the display. So every core is resampled at least a little, even one whose rate matches the output, because rate control adjusts the ratio by up to 0.5 %. mpv plays a file at its own rate.

The first rate column is the console's own: the rate its sound hardware produces samples at, or "analog" where the chip's channels are mixed as analog signals and there is no sample rate to speak of. The second is what the emulator hands RetroArch, taken from its source code at the pinned commit with PortareOS's options.

| Systems (default emulator) | Console's audio rate (Hz) | Emulator outputs (Hz) | Played at (Hz) |
|---|---|---|---|
| gb, gbh, gbc, gbch (Gambatte) | analog (the APU runs at 1,048,576) | 32,768 | 48,000 |
| gba, gbah, gbav (mGBA) | 32,768 by default; a game can pick up to 262,144 | 65,536 | 48,000 |
| snes, snesh, sfc, satellaview, sufami (Snes9x) | 32,000 nominal (about 32,040 on real consoles) | 32,040 | 32,000 |
| snesmsu1 (Snes9x) | 32,000, plus the MSU-1's 44,100 | 44,100 (MSU-1 enhanced audio) | 44,100 |
| nes, famicom, fds (Nestopia) | analog (the APU's channels are mixed as analog signals) | 48,000 (mixed at the APU clock, decimated) | 48,000 |
| psx (SwanStation) | 44,100 | 44,100 | 44,100 |
| saturn (Beetle Saturn) | 44,100 (SCSP) | 44,100 | 44,100 |
| mastersystem, sg-1000, gamegear, ggh (Genesis Plus GX) | analog (SN76489, 223,722 per channel step) | 44,100 | 44,100 |
| megadrive, megadrive-japan, megadriveh, genesis, genh (Genesis Plus GX) | 53,267 (YM2612), plus the SN76489 | 44,100 | 44,100 |
| segacd, megacd (Genesis Plus GX) | as the Mega Drive, plus 32,552 (RF5C164 PCM) and 44,100 (CD audio) | 44,100 | 44,100 |
| sega32x (PicoDrive) | as the Mega Drive, plus the 32X's PWM at a rate the game sets | 44,100 (`native` would give 53,267) | 44,100 |
| n64, n64dd (ParaLLEl N64) | set by the game (commonly 22,050 to 44,100) | the game's rate, exactly, e.g. 22,037.94; 32,040 until the game sets one | 48,000 |
| neogeo (FBNeo) | 55,555 (YM2610) | about 48,000 (47,990 at 59.18 fps) | 48,000 |
| neocd (NeoCD) | 55,555 (YM2610), plus 44,100 (CD audio) | 44,100 | 44,100 |
| arcade (FBNeo) | depends on the board | about 48,000, depending on the game's frame rate | 48,000 |
| dreamcast, naomi, atomiswave (Flycast) | 44,100 (AICA) | 44,100 | 44,100 |
| gamecube, triforce (Dolphin) | 32,029 (DSP), 48,000 (streamed disc audio) | 48,000 (asks RetroArch for its rate) | 48,000 |
| wii, wiiware (Dolphin) | 32,000 (DSP), 48,000 (streamed disc audio) | 48,000 (asks RetroArch for its rate) | 48,000 |
| ps2 (ARMSX2) | 48,000 (SPU2) | 48,000 (44,100 in PS1 mode) | 48,000 |
| xbox (xemu) | 48,000 (AC'97) | 48,000 | 48,000 |
| psp, pspminis (PPSSPP) | 44,100 | 44,100 | 44,100 |
| movies, music (mpv, gmu) | the file's rate | the file's rate | the file's rate |

In short:

- **No resampling needed:** the 44.1 kHz cores play at 44.1 kHz: PS1, Saturn, Dreamcast, NAOMI, Atomiswave, PSP, NeoCD and every other Sega system. Xbox, PS2, Dolphin and Nestopia already produce 48 kHz.
- **Nearly native:** the SNES plays at 32 kHz. The 32,040 → 32,000 conversion (0.125 %) is smaller than what rate control adjusts anyway.
- **Resampled as on any other device:** Game Boy, GBA, N64 and Neo Geo. Their rates match none of the link's rates, so they need resampling either way.

## Adding a mode

1. Find the system's exact native rate `f`, preferably from the rate the emulator logs at startup.
2. Compute the pixel clock `round(2 × f × 1302 × 1001 / 1000)` in kHz, add the mode to the driver patch next to the others, and update the hunk's line count.
3. Add the emulator and the rate `2 × f` to `set_ra_refresh_rate` in `setsettings.sh`. RetroArch accepts a mode within 1 Hz of the requested rate, and `setsettings.sh` only asks for a mode that the panel lists within 0.002 Hz.
4. Test the mode on the device: `modetest -c` lists it, and the picture stays stable while a game runs.

Open work is tracked in #284.
