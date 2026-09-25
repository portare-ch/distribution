# The color profiles: sRGB and D65 on the Nova's panel, at gamma 2.2 or the sRGB curve

The Nova's panel is wide-gamut and its white is blue-tinted. Shown as they are, sRGB games and films come out oversaturated (red at x = 0.68 where sRGB puts it at 0.64; green at 0.26/0.71 where sRGB has 0.30/0.60) and cool. [pippopapera measured it](https://github.com/pippopapera/nova-display-calibration) with an X-Rite i1Display Pro Plus, 921 readings, and published a correction for Android that brings 36 colors near the gamut boundary from a mean ΔE00 of 5.8 to 0.6. This is our version of that correction for Linux, and the honest account of how far it gets.

**Settings > Color profile** switches between *stock*, *Gamma 2.2* and *sRGB*. Both corrections aim at sRGB primaries and a D65 white; they differ in the tone curve. Gamma 2.2 is a pure power law, what CRTs did and what CRT-era games were drawn on, and it is the one to use for emulators. sRGB is the piecewise curve of the sRGB standard, with a linear toe that lifts the shadows (code 16 is 0.52 % of white against 0.23 % under gamma 2.2): a preference for someone who wants more visible detail near black on this OLED, not a correctness argument. The setting is `display.colorprofile` in `system.cfg` (`stock`, `gamma22`, `srgb`), the files are `/usr/config/color/gamma22.profile` and `srgb.profile`, and the launcher writes the chosen one into the display controller (portarelauncher `color.c`, `kms.c`). It holds for everything: every emulator, mpv, Steam, the launcher itself.

## Where the correction lives

Not in the games, not in a compositor, in the display controller. Qualcomm's DPU has a post-processing block per layer mixer (the DSPP) with three stages in order:

| stage | what it does | Android profile | mainline `drm/msm` |
|---|---|---|---|
| IGC | a 1D table per channel, 8-bit in → 12-bit linear out: the de-gamma | yes | **not driven** (`DEGAMMA_LUT` size 0) |
| PCC | a 3×3 matrix | yes | CRTC `CTM` |
| GC | a 1D table per channel, 1024 entries, 10-bit: the output curve | yes | CRTC `GAMMA_LUT` |

Mainline (`drivers/gpu/drm/msm/disp/dpu1/dpu_hw_dspp.c`) implements PCC and GC. The IGC on this SoC is version 4, whose table is loaded through the LUTDMA engine rather than by register writes (downstream `reg_dmav2_setup_dspp_igcv4`, `LUTBUS_BLOCK_IGC`), and mainline has no LUTDMA at all. So the linearisation stage the Android profile relies on is out of reach without a real driver project, and the correction has to be built from a matrix on gamma-encoded values followed by an output table.

The DPU applies the two blocks from the CRTC's state on every modeset (`_dpu_crtc_setup_cp_blocks`, called when color management changed or a modeset happened) and reserves a DSPP for the CRTC as soon as `CTM` or `GAMMA_LUT` is set. A later client's modeset — RetroArch's, mpv's — duplicates the CRTC state including both blobs, so what the launcher sets once stays in force until something clears it.

## How the profile was made

`projects/PortareOS/packages/portareos/sources/color/fit-profile.py`, from a checkout of their repository, once per tone curve (`gamma22`, `srgb`):

1. **A model of the panel.** Their 261 readings at the reference brightness (173/255) were taken through three pipelines: the factory one (39 readings, which we take as the raw panel: mainline applies no correction at all, so this is what PortareOS shows today) and their two profiles (222 readings). Their IGC, PCC and GC tables are published, so for every reading the value the panel was actually driven with is known. An additive display model — three primaries, one tone curve, and a brightness limiter that pulls white 7 % below the sum of the primaries, as measured — is fitted to all 261: median error 0.6 %. Run through it, their gamma 2.2 profile predicts a mean ΔE00 of 0.54 on the 36 boundary colors; they measured 0.63. That is the check that the model can be trusted.
2. **The correction for our pipeline.** A 3×3 matrix and a 22-knot monotone curve per channel, optimised together to minimise CIEDE2000 against sRGB primaries, D65 and the chosen tone curve — their targets and their equations (`tools/color_math.py`) — over the 36 boundary colors, the 56 reference patches, a 6×6×6 grid and a gray ramp, from eight starting points.
3. **The file.** `ctm` and 1024 `lut` lines, the DRM formats, with the predicted numbers in its header.

## What to expect

Predicted by the model, not measured — we have no colorimeter, and the second column is the whole point of writing this down:

Each profile is judged against its own target (gamma 2.2 or the sRGB curve), which is why the stock column differs between the two:

| set | stock → Gamma 2.2 profile | stock → sRGB profile |
|---|---|---|
| 36 gamut-boundary colors | 5.48 → **2.83** | 5.61 → **2.76** |
| 56 reference patches (grays, primaries, mixes, skin) | 5.13 → **3.38** | 5.29 → **3.19** |
| 6×6×6 grid | 4.68 → **2.01** | 4.81 → **1.82** |
| gray ramp, codes 8 to 255 | 3.98 → **1.93** | 4.34 → **1.99** |

Mean ΔE00; the maxima are in each file's header. White is driven at about 96 % of the stock luminance in both.

For comparison, the Android three-stage gamma 2.2 profile predicts 0.54 / 0.71 / 0.64 on the first three sets. The gap is the missing IGC: a matrix applied to gamma-encoded values desaturates a full-intensity color by the right amount and a darker one by too little, and no output table can undo that afterwards. Grays, the white point and the tone curve are exact in this pipeline; the residual is in saturated mid-tones. The darkest grays (codes 16 to 32) are uncertain in every profile, theirs included: the panel's black floor and the model's behaviour there are both poorly known.

White is dimmer with the profile on, as it is on Android (they lost 10 %): a D65 white on a blue-tinted panel means less blue, and the tone curve costs the rest. The brightness slider is untouched.

## Caveats

- **One unit measured, not this one.** Their readings are from their Nova. Panels of one model vary; expect to be close, not exact.
- **Raw panel = Android "original" is an assumption.** Their original readings went through the factory QDCM configuration, whose tables their installer enables (so they were off) but whose picture adjustment we cannot see. The model fits those 39 readings to 0.85 % median together with the rest, which is consistent with the assumption, not a proof.
- **Their spectral correction is a generic OLED CCSS**, marked provisional by them; absolute numbers inherit that.
- **Full-screen patches.** The brightness limiter was measured on full-screen colors; a game's average picture level is lower, so bright saturated areas in a game may sit a little differently.

## What would make it exact

Driving the IGC: a LUTDMA implementation in `drm/msm/dpu` (the downstream `sde_hw_reg_dma_v1.c` / `sde_hw_reg_dma_v1_color_proc.c` are the reference), then `DEGAMMA_LUT` with 256 entries. With that, their IGC, PCC and GC tables port one to one and the launcher's profile file gains a `degamma` section. Tracked in #161.

## Licence

The readings and tables the fit starts from are MIT, Copyright (c) 2026 pippopapera. The profile file and the fit script carry the notice.
