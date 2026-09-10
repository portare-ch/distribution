# Known bugs and loose ends

Things found and not fixed. GitHub issues are the tracker for work with a
shape; this file is the record of everything else, including findings too
small, too uncertain or too far from a fix to file. Nothing here is
speculative: each item is something observed on the device or read in the
tree, with enough detail to pick up cold.

Add to it when you leave something behind. When something is fixed, move it to
Resolved at the bottom rather than deleting it: what was wrong and why is worth
keeping, especially where the first few explanations were wrong.

## Unexplained

### Suspend power draw

Tracked in [#62](https://github.com/portare-ch/distribution/issues/62). The
device loses meaningful charge overnight and the cause is not known.

Three hypotheses were tested on hardware and all three were wrong:

* `apss` in `/sys/kernel/debug/qcom_stats/` reaching sleep was read as the SoC
  reaching sleep. It is the apps subsystem only.
* Interconnect `avg` votes were read as the DDR floor. Setting `ebi` to zero
  changed nothing.
* CPU frequency was read as what drives DDR. Moving the governor moved the
  clocks and DDR did not follow.

What is established: DDR has not touched its 200 MHz minimum since boot, in
any state, and with the frontend stopped it pins at 3187 MHz on an idle
system. `aosd`, `cxsd` and `ddr` in `qcom_stats` all read `Count: 0`, though
several files in that directory are empty on this SoC so the zeros may mean
"not reported" rather than "never entered".

Nobody has measured `/sys/class/power_supply/*/current_now`. Everything so far
has been proxies. Start there.

### CX never leaves performance state 64

`pm_genpd_summary` shows `cx on 64` with three holders: `898000.serial`
(uart14, the gamepad MCU by the `serial1` alias), `pcie_0_gdsc` at 64
(ath12k), and `mmcx` at 64 (display controller). Whether any of them releases
during suspend is unknown.

### 096-cpuidle

```sh
# Disable cpu0 idle state 1, seems to cause GMU issues
echo 1 > /sys/devices/system/cpu/cpu0/cpuidle/state1/disable
```

Inherited from ROCKNIX with no more explanation than that comment. We now know
the GMU does misbehave on this platform, so the workaround may be covering
something real. Nobody has established what, or whether the quirk still earns
its cost: `irqaffinity=0-2` sends every interrupt to the cluster it cripples.

### pcie_ports=compat

On the kernel cmdline, which disables the PCIe port services including PME.
`CONFIG_PCIEASPM_DEFAULT=y` leaves link power states at whatever firmware set,
and Qualcomm firmware commonly leaves ASPM off. Never investigated. Costs
power awake as well as asleep if the ath12k link never reaches L1SS.

## Patches applying with fuzz

`scripts/unpack` runs `patch -p1`, which takes GNU patch's default fuzz factor
of 2. A hunk can apply with two lines of context discarded and the build says
nothing. Verified by unpacking the real trees and applying the real patch sets.

**Kernel, 17 of 83** need reduced context, identically on 7.2.2 and 7.2.4, so
the version bump did not cause it:

`0002` input-polldev, `0005` btrtl RTL8733BU, `0033` HTR3212 leds,
`0055` `0056` `0057`x2 `0104` `0105` panels, `0058` Odin2 Mini backlight,
`0059` hynitron, `0121` rpmhpd gmu rails, `0210` sdhci-msm,
`0501` wifi/bt mac, `0504` compat input syscalls, `1003` rsinput ff, and the
qce runtime-pm patch.

Most are for hardware this fork does not build. Three are ours: `0105` is the
Nova panel, `0210` is the microSD SDR104 work, `1003` is gamepad force
feedback.

**`1051`** makes `git apply` report `corrupt patch at line 32` on both
kernels. It is not corrupt in any way that matters: its final context line is
bare rather than a single space, which `git apply` refuses and GNU `patch`
accepts. Confirmed by padding that line, after which the 124.8 MHz GPU
operating point lands at `sm8550.dtsi:2644`. The real build has it.

Making the build reject fuzz outright (`patch -F0`) would need all of these
regenerated first.

## Dolphin

### Soul Calibur II freezes

Diagnosed but unconfirmed. `Dolphin.ini` ran Dual Core with
`SyncOnSkipIdle = False` and `SyncGPU = False`, which is the exact combination
`CommandProcessor::HandleUnknownOpcode` singles out as making an unknown FIFO
opcode "very likely". `SyncOnSkipIdle` is restored to upstream's default.

It still freezes, so that was not it, or not all of it. Dolphin's own
escalation from here is `SyncGPU = True`, then `CPUThread = False`. One at a
time. `/var/log/exec.log` now carries the reason, since the patch that silenced
20 PanicAlerts is gone.

What the kernel rules out: a 2.5 hour dmesg covering a play session has no GPU
fault, no `*ERROR*` from msm, no hung task, no rcu stall, no OOM. One
`dpu_encoder_resource_control: invalid parameters` from the display controller,
once, and nothing else. So whatever stops is stopping in userspace, without the
kernel noticing. That is Dolphin's own threads or the Vulkan driver deadlocking
before it submits anything the kernel would object to, and it argues against
the GPU firmware being the cause.

The measurement nobody has taken: while it is frozen, dump per-thread state.

    P=$(pidof dolphin-emu-nogui)
    for t in /proc/$P/task/*; do
      echo "$(basename $t) $(cut -d' ' -f3 $t/stat) $(cat $t/wchan) $(cut -d' ' -f1 $t/syscall)"
    done

That separates the three candidates in one shot. Threads blocked in an ioctl on
a DRM fd means the driver. Everything in a futex wait means a deadlock between
Dolphin's own threads. A thread in state R with no syscall means the JIT is
spinning.

Soul Calibur III is not a way around this: it is PS2 only, so it belongs to
armsx2, which is reported to run fine.

### Truncations in the 240p patch

`004-enable-240p-res.patch` assigns `GetEFBScalef()` to an `unsigned int` in
`TryToSnapToXFBSize` and to an `int` in `GetCustomCrop`, both in `Present.cpp`.
At the 240p setting a scale of 0.5 truncates to 0. Neither crashes and both
affect only that one resolution. Left alone because picking a rounding is a
design call, not a fix.

## Flycast

### Tony Hawk's Pro Skater stutters

The audio backend was changed from `pulse` to `sdl2` when pulseaudio was
removed, on the theory that the backend was behind the stutter. It still
stutters, so it was not.

The change did reach the device: `start_flycast.sh` rewrites `backend =` in an
existing `/storage/.config/flycast/emu.cfg` on every launch, so a config
predating the switch is not the explanation.

Nor is staleness. `PKG_VERSION` is `5aa091f`, which is exactly `v2.7`, the
newest tag upstream has.

Measured. The counter sits at 30, dips to 26 when the audio stutters, and
falls as far as 9 at its worst. So this is not presentation: frames are not
being made. Whatever is wrong is upstream of the compositor.

9 fps is three times the frame budget, which is too large for scheduler jitter.
It is a stall, a clock collapse or a block on something. Three candidates, and
one measurement covers all of them, taken over ssh while the stutter happens:

    while :; do echo "$(date +%T) $(for f in \
      /sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq; do \
      printf '%s ' $(( $(cat $f)/1000 )); done)| \
      $(cat /sys/class/thermal/thermal_zone*/temp|sort -n|tail -1|cut -c1-2)C"; \
      sleep 1; done

Thermal, if the clocks fall and the temperature is high. Governor, if the
clocks are low and the temperature is not: `irqaffinity=0-2` puts every
interrupt on the little cluster, and switching to schedutil dropped that
cluster's idle clock from 2016000 kHz to 556800. That change was made in this
tree, recently, and this is the shape of symptom it could produce. Neither, if
the clocks hold, and then it is a block rather than a shortage.

Worth ruling out separately: flycast synchronises to audio, so a stalling audio
backend does not merely follow a frame drop, it can cause one. `backend = alsa`
against the current `sdl2` is the cheap A/B, and it also tests the sdl2 switch
that was made when pulse was removed.

Also unexplained, and possibly a separate bug: the baseline is 30, not 60.

Note that `pvr.AutoSkipFrame` is not it unless the ES `auto_frame_skip` setting
has been set by hand. Nothing in the tree defines a default for it, so
`get_setting` comes back empty and the launcher takes the `else` arm, which
writes 0.

## Audio

### hdmi_sense sink match is unverified

The external display is DisplayPort over USB-C alt mode, so the connector is
`DP-1`. The script now scans DP connectors and matches sinks on `hdmi`,
`displayport` and `dp`, on the assumption that the ALSA device behind a DP
output is still named for HDMI on this SoC. **Nobody has docked the device and
run `wpctl status` to check.** If the sink matches none of those, the regex
needs another alternative.

### Two pactl calls dropped rather than ported

* `set-default-source <sink>.monitor` has no PipeWire equivalent: a monitor is
  a port on the sink node, not a node, so there is no id to make default.
  `pipewire-pulse` synthesises those sources for pulse clients only. This is a
  real behaviour change and nobody has said whether it mattered.
* `set-card-profile` was already dead. `DEVICE_PIPEWIRE_PROFILE` is exported in
  `quirks/profile.d/999-export` and never assigned.

### Names that lie

`hdmi_sense`, its udev rule `99-hdmi.rules` and its status file
`/run/hdmi-status.last` are all named for hardware this device does not have.

## Display and power

### /usr/bin/external-display is not in the tree

`power-handler` calls it and degrades to a sway fallback. The helper is
referenced in comments as the thing that blanks internal panels only, and it
has never existed here. Either write it or finish removing the indirection.

### The DPMS toggle is gone

`system.suspend.dpms` chose between a real DPMS off and dropping the backlight.
Its only reader was `portareos-fake-suspend`, removed in `a61c3f72a4`, and the
setting went with it. The blank path now always does a real DPMS off through
sway, which is the better default, but the choice no longer exists.

### The power LED does not exist

`sleep.d/pre/000-led`, `sleep.d/post/099-led-restore` and `power-handler` all
write to `/sys/class/leds/power-led`. That node is declared only in the AYN and
AYANEO device trees, so every `[ -d "${POWER_LED}" ]` guard is false here and
the writes never happen. Dead, not harmful. The analogue stick LEDs are real
and that code stays.

Worth knowing: `power-handler` lights the LED at press time specifically so the
press does not feel dead while WiFi tears down. On this device that comfort
feature does nothing.

## EmulationStation

### Unknown element of type "notification"

`es_log.txt` carries repeated `Unknown element of type "notification"!`
warnings from theme parsing. Cause unknown, and no symptom is attached to them.

### The frontend has no damage tracking

`main.cpp` calls `window.render()` and `Renderer::swapBuffers()` every loop
iteration regardless of whether anything changed. The fps cap and the freeze on
blank work around it; neither fixes it. Damage tracking is the real answer and
is a large piece of work.

### isAvailable() is gone

Removed in `emulationstation-next#12` because its only caller hid the whole
VOLUME group, including two settings that have nothing to do with PipeWire.
Noted here in case a future import expects it.

## rsinput

### Truncated frames are still dropped

`1013` fixed the batch-wide checksum that was discarding whole receive batches
and added header resynchronisation. What it does not do is buffer a partial
frame for the next callback: `rsinput_process_data()` returns when
`len < frame_length` and those bytes are lost. Proper reassembly needs
persistent state across callbacks.

## Build and process

### Changed defaults still need a migration

Half fixed. `post-update` now runs an `--ignore-existing` pass over
`/usr/config`, so a config file that is *new* in an image reaches a device
that has already booted, where before only `userconfig-setup` did that and
only once, guarded by `/storage/.configured`.

A changed *value* inside a file the install already has still cannot be
delivered that way, and needs a one-shot migration at the bottom of
`post-update`. There is a `migrate` helper and a marker directory for it now,
so each runs once and a later deliberate choice is not undone on the next
update. Two exist, for `system.cpugovernor` and `FpsLimit`.

The trap to remember: shipping a new default in a config file is not enough on
its own. Ask whether an existing device can receive it.

### Do not reuse a merged branch

Three pull requests, [#59](https://github.com/portare-ch/distribution/pull/59),
[#61](https://github.com/portare-ch/distribution/pull/61) and
[#73](https://github.com/portare-ch/distribution/pull/73), arrived as conflicts
that were really reverts: a branch whose PR had already merged, still carrying
old copies of merged work and a base predating later merges. Merging any of
them would have undone real changes.

A branch whose PR has merged is spent. Start a fresh one from the new default
branch.

### "does not close #62" closes #62

GitHub's linked-issue parser matches `close #62` and ignores the negation, so
that sentence in a pull request body closes the issue it disclaims. It happened
once, in #70, and the same phrasing sits in #68's commit message.

## Resume time

rsinput and Bluetooth are under Resolved, worth about 3.2s between them. What
is left:

* **WiFi**, was 10.6s to `associated`. The rfkill is not optional:
  `ath12k_core_continue_suspend_resume()` returns 0 and does nothing unless
  `ar->ah->state == ATH12K_HW_STATE_OFF`, and `wcn7850 hw2.0` does carry
  `.supports_suspend = true`, so the radio has to be down for the driver's
  suspend path to run at all. The reassociation cannot be avoided.

  Measured split: NetworkManager's wake is only ~1.1s, consistently, and a
  flat `sleep 4` in `wifi-resume` was better than a third of the total. That
  is now a readiness poll, and it reports `WIFI ready after 0ms`, meaning iwd
  answered on the first try and the whole four seconds was wasted. Or meaning
  the readiness test answers before the chip is up, in which case the scan
  fires too early and iwd's backoff costs a minute. Those look identical from
  that log line. **Nobody has measured resume to `associated` since**, and
  that is the one number that separates them.

  What remains beyond it is the firmware reload on unblock and the scan
  itself, roughly 5s. Association once the scan lands is 26ms, so the scan is
  the target. A directed scan on the pinned network's channel would be the
  thing to try, but `iwctl` does not expose one.

`CONFIG_PM_DEBUG` is off, so `pm_print_times` is unavailable and per-device
suspend and resume timings have to be read out of `dmesg` timestamps by hand.
Turning it on is cheap and would make this measurable.

## Resolved

Kept rather than deleted. Several of these took more than one explanation to
find, and the wrong ones are recorded too.

### The gamepad failed to resume

`rsinput_rx()` treated every serdev receive callback as exactly one frame:
checksum the whole batch, discard it all on a mismatch. serdev frames nothing,
so a batch holding two frames, a partial frame, or a frame behind power-cycle
noise was thrown away entire. At resume that was the MCU's version reply, so
the handshake added in `1012` timed out three times and gave up with
`-ETIMEDOUT`, burning 1.48s of a 2.85s kernel resume and leaving the pad on a
driver that had given up.

`rsinput_process_data()` already validated each frame separately, so the fix in
`1013` was to delete the batch-wide check and add header resynchronisation.

**Confirmed on hardware.** Across three resumes the version reply is parsed and
the parameters acknowledged 13ms later, with no `Checksum mismatch`, no timeout
and no `-110`. That the reply is parsed at all is the proof: the batch checksum
destroyed it before.

Worth remembering: `1012` was blamed first, and it was innocent. It could not
succeed while the layer beneath it was discarding the reply.

### Bluetooth reloaded its firmware on every resume

1.76s of `hmtbtfw20.tlv` and `hmtnv20.bin` on each resume, and self-inflicted.
`hci_qca` sets `HCI_QUIRK_NON_PERSISTENT_SETUP` when it controls the chip's
power, and `hci_dev_setup_sync()` then runs `hdev->setup` on *every* open, not
just the first. `sleep.sh` stopping bluetoothd is what closed the device.
`qca_pm_ops` already carries the controller through system suspend in in-band
sleep with its firmware intact, so it just had to be left alone.

**Confirmed on hardware.** `QCA Downloading` now appears only at boot, at 2.9s
and 4.0s uptime, and on none of three later resumes.

Untested: whether a paired controller still reconnects after resume. That is
the failure mode that would send this back, and restoring the two `systemctl`
calls in `sleep.sh` is the whole revert.

### EmulationStation had no volume bar and no volume control

Three separate faults wearing one symptom, which is why it took three goes.

1. **The hardware +/- keys never reached ES at all.** `ViewController::input`
   maps volume to `joystick2up`, the right stick. `input_sense` owns the
   physical keys and calls `/usr/bin/volume`.
2. **`/usr/bin/volume` was broken by the pulse ban.** It ended in `pactl
   set-sink-volume`, and #54 deleted `pactl`. Fixed in #63 by moving to
   `wpctl`, with the cubic curve converted explicitly since `wpctl` takes a
   linear factor where `pactl` took a percentage.
3. **ES could not reach PipeWire.** `PipeWireControl` was a file-scope static,
   so its constructor ran before `main()` and before the log existed: every
   error went nowhere and a single failed connect was permanent. Fixed in
   `emulationstation-next#12` by constructing on first use and retrying.

**Confirmed on hardware.** The overlay now appears on a hardware volume press,
which exercises the entire chain in one go: `input_sense` to `/usr/bin/volume`
to `wpctl` setting the sink, `node_param` seeing `channelVolumes` change on the
PipeWire loop thread, and `VolumeInfoComponent` noticing the new value 40ms
later.

A wrong turn worth recording: the missing overlay was blamed on the
`Unknown element of type "notification"` theme warnings. It was not them, and
they are still there.

### dwc3 never runtime suspended

`a600000.usb` held `avg 1000000  peak 2500000` on the path to `ebi`
permanently, awake, on battery, with nothing plugged in. Those are
`USB_MEMORY_AVG_SS_BW` and `USB_MEMORY_PEAK_SS_BW` from `dwc3-qcom.c` to the
digit. `dwc3_core_probe()` ends with `pm_runtime_forbid()` and the only
`pm_runtime_allow()` calls are on error and teardown paths, so `power/control`
stayed `on` and `dwc3_qcom_runtime_suspend()`, which is what calls
`dwc3_qcom_interconnect_disable()`, could never run.

**Confirmed on hardware.** Writing `auto` took `runtime_status` to `suspended`,
the usb row to `0 0`, and the `ebi` aggregate from 1735805 to 735805. Shipped
as a udev rule in #70.

This is an awake-power fix. The system suspend path drops the vote by itself
through `dwc3_qcom_pm_suspend()`, so it does not touch the suspend draw.

### Blanking the panel did not blank anything

`power-handler` called `external_display blank`, and
`/usr/bin/external-display` is not in this tree, so the call returned 1 and
nothing happened. The flag was set, the backlight went dark on a separate path,
and the DPU carried on scanning out at 120Hz behind it.

**Confirmed on hardware.** `swaymsg "output * power off"` takes
`ae00000.display-subsystem` from `avg 735805` to `0` and the whole `ebi`
aggregate with it. A sway fallback is in place, internal outputs only.

### ondemand parked the little cluster at maximum

`008-perfmode` preferred `ondemand` wherever it existed. **Measured**: policy0
at 2016000 kHz on a 97% idle system, dropping to 556800 under `schedutil`. That
is also the cluster `irqaffinity=0-2` sends every interrupt to.

It did not move DDR, which was the hypothesis it was meant to test, but it
stands on its own.
