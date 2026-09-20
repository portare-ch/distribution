#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

# Fetch one stage's ccache archive from the cache release and unpack it.
#
# Every stage used to inline this as
#
#   curl ... "$URL" | tar -xvf - || echo "Cache archive not found, skipping."
#
# which is wrong in two ways that cost us three hours on 2026-09-20. The
# pipeline's exit status is tar's, not curl's, so a 404 was only noticed
# because tar then choked on an empty stream - and a genuinely corrupt
# archive produced exactly the same message as a missing one. More
# importantly the message was an echo, so "this stage is about to build
# every object from cold" appeared as ordinary text four thousand lines
# into the log, and the only visible symptom was a stage that took three
# times as long as usual for no stated reason.
#
# A missing ccache is not an error - a stage that has never run has none,
# and the build is correct either way - so this still exits 0. It just
# says so as a warning, which GitHub surfaces in the run summary next to
# the job, where the next person wondering why the toolchain took 167
# minutes will actually see it.

set -u

URL="${1:?usage: retrieve-ccache.sh <url> <label>}"
LABEL="${2:?usage: retrieve-ccache.sh <url> <label>}"

ARCHIVE="$(mktemp)"
trap 'rm -f "${ARCHIVE}"' EXIT

# The fallback has to live outside the substitution. Inside it, curl has
# already written its own "000" to stdout before failing, and an "|| echo
# 000" there appends a second one - which is how this first reported
# "HTTP 000000".
code="$(curl -L --silent --show-error --write-out '%{http_code}' \
  -o "${ARCHIVE}" "${URL}")" || code="000"

case "${code}" in
  200)
    ;;
  404)
    echo "::warning title=cold ccache::${LABEL} has no ccache in the cache release (404). This stage will compile everything from cold."
    exit 0
    ;;
  *)
    echo "::warning title=cold ccache::${LABEL} could not fetch its ccache (HTTP ${code}). This stage will compile everything from cold."
    exit 0
    ;;
esac

# wc pads its output with spaces on some platforms, which lands in the
# middle of the warning text below.
size="$(wc -c < "${ARCHIVE}" | tr -cd '0-9')"
if ! tar -xf "${ARCHIVE}"; then
  echo "::warning title=corrupt ccache::${LABEL} downloaded ${size} bytes of ccache that tar refused to extract. This stage will compile everything from cold."
  exit 0
fi

echo "${LABEL}: unpacked $((size / 1048576)) MB of ccache."
