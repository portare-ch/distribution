# Known bugs and loose ends

Things found and not fixed. GitHub issues are the tracker for work with a
shape; this file is the record of everything else, including findings too
small, too uncertain or too far from a fix to file. Nothing here is
speculative: each item is something observed on the device or read in the
tree, with enough detail to pick up cold.

Add to it when you leave something behind. Delete an entry when it is fixed,
not when it is filed.

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

If it still freezes, Dolphin's own escalation is `SyncGPU = True`, then
`CPUThread = False`. Change one at a time. `/var/log/exec.log` now carries the
reason, since the patch that silenced 20 PanicAlerts is gone.

### Truncations in the 240p patch

`004-enable-240p-res.patch` assigns `GetEFBScalef()` to an `unsigned int` in
`TryToSnapToXFBSize` and to an `int` in `GetCustomCrop`, both in `Present.cpp`.
At the 240p setting a scale of 0.5 truncates to 0. Neither crashes and both
affect only that one resolution. Left alone because picking a rounding is a
design call, not a fix.

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

### The volume overlay may be a theme problem

`es_log.txt` carries repeated `Unknown element of type "notification"!`
warnings. If the on-screen volume overlay is drawn as a theme notification
element, that is why it does not appear, and it is a theme fault rather than a
code one. `VolumeInfoComponent` itself is fine: it polls `getVolume()` every
40ms and shows on a change, and the connection bug behind it was fixed in
`portare-ch/emulationstation-next#12`.

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

Roughly 2.9s in the kernel plus a long userspace tail, measured from `dmesg`:

* **rsinput**, was 1.48s of the kernel's 2.85s, burning its full handshake
  retry budget and then failing with `-110`. Fixed in `1013` and **confirmed on
  hardware**: across three resumes the version reply is parsed and the
  parameters acknowledged 13ms later, with no `Checksum mismatch`, no timeout
  and no `-110`. That the reply is parsed at all is the proof, since the
  batch-wide checksum destroyed it before.
* **Bluetooth**, was 1.76s. It did not need to stop at all, and `sleep.sh` no
  longer does. `hci_qca` sets `HCI_QUIRK_NON_PERSISTENT_SETUP` when it controls
  the chip's power, so `hdev->setup` and its firmware download run on every
  open, while `qca_pm_ops` already suspends the controller into in-band sleep
  without losing the firmware. **Confirmed on hardware**: `QCA Downloading`
  now appears only at boot, at 2.9s and 4.0s uptime, and not on any of three
  later resumes. Still worth watching whether a paired controller reconnects,
  which nobody has tested with one attached.
* **WiFi**, 10.6s to `associated`. The rfkill is not optional:
  `ath12k_core_continue_suspend_resume()` returns 0 and does nothing unless
  `ar->ah->state == ATH12K_HW_STATE_OFF`, and `wcn7850 hw2.0` does carry
  `.supports_suspend = true`, so the radio has to be down for the driver's
  suspend path to run at all. The reassociation cannot be avoided.

  Measured split: NetworkManager's wake is only ~1.1s, consistently, and a
  flat `sleep 4` in `wifi-resume` was better than a third of the total. That
  is now a readiness poll. What remains is the firmware reload on unblock and
  the scan itself, roughly 5s, and nobody has attacked it. Association once
  the scan lands is 26ms, so the scan is the target. A directed scan on the
  pinned network's channel would be the thing to try, but `iwctl` does not
  expose one.

`CONFIG_PM_DEBUG` is off, so `pm_print_times` is unavailable and per-device
suspend and resume timings have to be read out of `dmesg` timestamps by hand.
Turning it on is cheap and would make this measurable.
