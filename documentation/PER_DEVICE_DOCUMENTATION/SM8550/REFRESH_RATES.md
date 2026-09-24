# Refresh rates on the Retroid Pocket Nova (SM8550)

The panel has no variable refresh rate. It runs at **119.880120 Hz**, twice NTSC's 59.94 Hz. For systems whose native rate is noticeably different, `setsettings.sh` (`set_ra_refresh_rate`) asks for a panel mode at exactly twice that rate, and RetroArch switches to it when the game starts.

Every mode uses the same 1302 × 1001 total timings and changes only the pixel clock. That keeps the panel in its 120 Hz class. The modes are defined in the panel driver, `projects/PortareOS/devices/SM8550/patches/linux/0105-drm-panel-Add-Retroid-Pocket-Nova-panel.patch`.

| Panel mode | Pixel clock | Used by |
|---|---|---|
| 119.880120 Hz | 156240 kHz | default (launcher, everything else) |
| 119.634590 Hz | 155920 kHz | `swanstation` |
| 119.455046 Hz | 155686 kHz | `gambatte`, `mgba` |
| 120.197775 Hz | 156654 kHz | `snes9x`, `bsnes` |

## Systems

The rates are the original NTSC hardware's frame rate, or for handhelds the hardware's own rate.

| Systems (default emulator) | Native rate (Hz) | Panel mode (Hz) |
|---|---|---|
| gb, gbh, gbc, gbch (Gambatte) | 59.7275 | 119.455 |
| gba, gbah, gbav (mGBA) | 59.7275 | 119.455 |
| snes, snesh, sfc, satellaview, sufami, snesmsu1 (Snes9x) | 60.0988 | 120.198 |
| psx (SwanStation) | 59.8173 | 119.635 |
| mastersystem, sg-1000, gamegear, ggh (Genesis Plus GX) | 59.9227 | 119.880 |
| megadrive, megadrive-japan, megadriveh, genesis, genh (Genesis Plus GX) | 59.9227 | 119.880 |
| segacd, megacd (Genesis Plus GX) | 59.9227 | 119.880 |
| sega32x (PicoDrive) | 59.9227 (the emulator reports 60) | 119.880 |
| n64, n64dd (ParaLLEl N64) | about 60 (the emulator reports 60) | 119.880 |
| neogeo (FBNeo), neocd (NeoCD) | 59.1856 | 119.880 |
| arcade (FBNeo) | depends on the game's board (about 54–61) | 119.880 |
| dreamcast, naomi, atomiswave (Flycast) | 59.94 | 119.880 (exactly 2×) |
| gamecube, triforce, wii, wiiware (Dolphin) | 59.94 | 119.880 (exactly 2×) |
| ps2 (ARMSX2) | 59.94 | 119.880 (exactly 2×) |
| xbox (xemu) | 59.94 | 119.880 (exactly 2×) |
| psp, pspminis (PPSSPP) | 59.94 | 119.880 (exactly 2×) |
| scummvm, steam, ports | no fixed rate (PC games) | 119.880 |
| movies (mpv) | the video's frame rate (23.976, 25, 29.97 …) | 119.880; mpv syncs video to audio |
| music, moonlight, tools, imageviewer | – | 119.880 |

## Adding a mode

1. Find the system's exact native rate `f`, preferably from the rate the emulator logs at startup.
2. Compute the pixel clock `round(2 × f × 1302 × 1001 / 1000)` in kHz, add the mode to the driver patch next to the others, and update the hunk's line count.
3. Add the emulator and the rate `2 × f` to `set_ra_refresh_rate` in `setsettings.sh`. RetroArch accepts a mode within 1 Hz of the requested rate, and `setsettings.sh` only asks for a mode that the panel lists within 0.002 Hz.
4. Test the mode on the device: `modetest -c` lists it, and the picture stays stable while a game runs.

Open work, including candidate modes for Neo Geo (118.371 Hz) and Sega 8/16-bit (119.846 Hz), is tracked in #284.
