#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present PortareOS

"""Let the AYN-Odin2 topology's playback PCMs open at 44100.

The topology caps MultiMedia1 and MultiMedia2 Playback at rate_min =
rate_max = 48000, which pins the frontend to 48 kHz before any kernel
rate mask is consulted. The DSP graph carries no rate of its own, so
widening those two capability blocks is the whole change: rates becomes
44100|48000, rate_min 44100, rate_max 48000. Capture is left alone.

Rebuilding from the AudioReach topology source was the first choice, but
the LineageOS AYN-Odin2.m4 does not reproduce this binary, so the shipped
file is edited in place and both ends are checked by hash.
"""

import hashlib
import struct
import sys

IN_SHA256 = "0e530c1fea0767c21b39bb1149fab01c17a7c736e78d84a63803f8f467784241"
OUT_SHA256 = "685b709427b9b438e14e6d49723b4de97b2daaef39e72bdafb0a4243f551d211"

TPLG_MAGIC = 0x41536F43
TPLG_TYPE_PCM = 7
PCM_STREAM_SIZE = 72
PCM_CAPS_SIZE = 104
SNDRV_PCM_RATE_44100 = 1 << 6
SNDRV_PCM_RATE_48000 = 1 << 7


def patch(data):
    off = 0
    patched = []
    while off + 36 <= len(data):
        magic, _abi, _ver, typ, hsize, _vtype, psize, _index, count = \
            struct.unpack_from("<IIIIIIIII", data, off)
        if magic != TPLG_MAGIC:
            sys.exit(f"bad topology block magic at {off}")
        body = off + hsize
        if typ == TPLG_TYPE_PCM:
            p = body
            for _ in range(count):
                size = struct.unpack_from("<I", data, p)[0]
                name = data[p + 4:p + 48].split(b"\0")[0].decode()
                playback, capture = struct.unpack_from("<II", data, p + 100)
                caps = p + 112 + 8 * PCM_STREAM_SIZE + 4
                if playback and not capture:
                    struct.pack_into("<III", data, caps + 56,
                                     SNDRV_PCM_RATE_44100 | SNDRV_PCM_RATE_48000,
                                     44100, 48000)
                    patched.append(name)
                p += size
        off = body + psize
    return patched


def main():
    if len(sys.argv) != 2:
        sys.exit(f"usage: {sys.argv[0]} AYN-Odin2-tplg.bin")
    path = sys.argv[1]
    data = bytearray(open(path, "rb").read())

    if hashlib.sha256(data).hexdigest() != IN_SHA256:
        sys.exit(f"{path}: not the topology this edit was made for")

    patched = patch(data)
    if patched != ["MultiMedia1 Playback", "MultiMedia2 Playback"]:
        sys.exit(f"{path}: unexpected playback PCMs {patched}")
    if hashlib.sha256(data).hexdigest() != OUT_SHA256:
        sys.exit(f"{path}: edit produced an unexpected file")

    open(path, "wb").write(data)
    print(f"{path}: {', '.join(patched)} now allow 44100")


if __name__ == "__main__":
    main()
