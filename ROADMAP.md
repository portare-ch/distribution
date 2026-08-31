# Roadmap

Intent, not promise. Ordered roughly by how much difference each would make.

**Nothing here has been tested on hardware.** The tree builds and the changes
are internally consistent; whether the Nova boots with them is unverified.
Three of these are blocked on measurement rather than code, and there is no
test rig yet: a 240 fps camera and a way to trigger a known input.

## The goal

A straight replacement for the stock Android install. Write the card, copy the
games across, and every emulator is already set up for this handheld. Not
generic defaults, but per-system settings picked for the Nova. Latency first,
because that is what Android on this device is worst at, then performance and
visuals wherever they can be had without being paid for in input lag.

## Planned

### Every emulator configured on arrival

Per-system settings tuned for this panel and this gamepad, shipped as
defaults rather than left to the user. The display geometry work below is the
start of this; the rest is a long tail of per-emulator configuration.

### Replace sway

sway is a tiling compositor built for desktops with a keyboard and a pointer.
On a 4:3 handheld driven by a d-pad and four face buttons it gets in the way:
configuration dialogs in standalone emulators such as ARMSX2 open at sizes
this panel cannot show, with no comfortable way to scroll, reach or dismiss
them. The device needs something that draws one fullscreen window at a fixed
resolution. It may not want a compositor at all, which is where this meets the
latency question below.

### Button glyphs that match the buttons

The Nova's face buttons are physically swappable, so the glyphs drawn on
screen and the buttons under a thumb can disagree about both symbol and
position. Wanted: a configurator recording which set is fitted, covering glyph
style (PlayStation, GameCube, Xbox, Nintendo) and layout, applied system-wide.

The work is in `portare-ch/emulationstation-next`, not in a driver. ES resolves
help glyphs through a flat table in
`es-core/src/components/HelpComponent.cpp` mapping names to a single set of
SVGs under `resources/help/`. There is no style switch today. RetroArch draws
its own glyphs and will need separate work.

### Performance

GPU frequency and operating points, pinning emulator threads to the Cortex-X3
rather than letting the scheduler move them onto the little cores mid-frame,
and governor tuning.

`scx_lavd` covers part of this already, below.

## In progress

### More 4:3

The render geometry is corrected and integer scaling is on where the maths
works out. Bezels and overlays are still drawn for 16:9, shader presets still
assume a widescreen viewport, and there are more defaults carrying 1080p
assumptions than the ones found so far.

Lives in `projects/PortareOS/packages/hardware/quirks/devices/Retroid Pocket Nova/`.

### sched_ext and scx_lavd

`scx_lavd`, the latency-aware big.LITTLE scheduler, is packaged and the kernel
config chain is enabled: `SCHED_CLASS_EXT`, BTF, and the tracing core it needs.
Built but never run.

The service switches the governor to schedutil on start and restores
performance on stop, so a device not running it behaves as before. That makes
it a clean A/B once there is a way to measure.

### A build that does not waste hours

Landed: the Docker image is rebuilt only when its Dockerfile changes, which
also stops the host compiler drifting under the compiler cache; an opt-in
incremental mode that skips packages whose recipes have not changed; builds
serialised, because two at once overwrote each other's caches; and
`check-package-deps.py` catching a dependency naming a package that is not in
the tree, in seconds rather than part-way through a build.

Remaining: stage-output caching, and a `kernel_only` dispatch input.

## Open questions

### Input latency without Wayland

The emulator frame queue is already at zero. The larger question is whether
the compositor can be taken out of the path entirely and emulators handed the
display directly through KMS/DRM. Best case that removes a whole frame.

Overlaps with replacing sway: one answer may make the other unnecessary.

### Audio stack

Untouched and unmeasured. Worth finding out what the current pipeline costs in
latency and whether any of it can be shortened or taken out.

## Not planned

Support for any device other than the Retroid Pocket Nova. Everything else was
removed from the tree deliberately; see the README.
