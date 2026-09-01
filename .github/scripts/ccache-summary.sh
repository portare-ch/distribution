#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Report one stage's ccache hit rate into the job summary.
#
# Every build stage already runs "ccache -s -v" twice and throws the output
# into a log nobody reads. The open question is whether the cache is earning
# the time it costs to download and upload: a stage whose working set does not
# fit in its configured limit pays for the transfer and then misses anyway.
# That is invisible in a log and obvious in a table, so this puts one row per
# stage into the run summary where the stages can be compared side by side.
#
# Nothing here may fail a build. ccache's own output format has changed across
# versions and the toolchain builds its own copy, so every read is best-effort
# and a stage that cannot be measured simply reports "unknown".
#
# Usage: ccache-summary.sh <ccache-binary> <stage-label>

set -uo pipefail

CCACHE="${1:-}"
LABEL="${2:-unknown}"

emit() {
  # Outside Actions there is no summary file; print instead so local runs work.
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '%s\n' "$1" >> "${GITHUB_STEP_SUMMARY}"
  else
    printf '%s\n' "$1"
  fi
}

emit "### ccache"
emit ""
emit "| stage | hit rate | hits | misses | cache |"
emit "|---|---|---|---|---|"

if [ ! -x "${CCACHE}" ]; then
  emit "| ${LABEL} | no ccache binary | | | |"
  exit 0
fi

# ccache 4.x gives key/value pairs that are stable across versions; older
# builds do not have it, and fall through to parsing the human table.
stats="$("${CCACHE}" --print-stats 2>/dev/null || true)"

hit="" miss="" size="" max=""
if [ -n "${stats}" ]; then
  direct="$(awk '$1=="direct_cache_hit"{print $2}' <<<"${stats}")"
  preproc="$(awk '$1=="preprocessed_cache_hit"{print $2}' <<<"${stats}")"
  miss="$(awk '$1=="cache_miss"{print $2}' <<<"${stats}")"
  size="$(awk '$1=="cache_size_kibibyte"{print $2}' <<<"${stats}")"
  max="$(awk '$1=="max_cache_size_kibibyte"{print $2}' <<<"${stats}")"
  hit=$(( ${direct:-0} + ${preproc:-0} ))
fi

if [ -z "${miss}" ]; then
  human="$("${CCACHE}" -s 2>/dev/null || true)"
  hit="$(awk -F'[ ]+' '/^[Cc]ache hit/{print $NF}' <<<"${human}" | head -1)"
  miss="$(awk -F'[ ]+' '/^[Cc]ache miss/{print $NF}' <<<"${human}" | head -1)"
fi

: "${hit:=0}" "${miss:=0}"
total=$(( hit + miss ))

if [ "${total}" -eq 0 ]; then
  emit "| ${LABEL} | no compilations | 0 | 0 | |"
  exit 0
fi

rate=$(( hit * 100 / total ))

usage=""
if [ -n "${size:-}" ] && [ -n "${max:-}" ] && [ "${max:-0}" -gt 0 ]; then
  usage="$(( size / 1024 )) MiB of $(( max / 1024 )) MiB"
  # A cache pressed against its ceiling is evicting work it is about to want
  # again, which is the shape of a limit that is too small rather than a cache
  # that is not helping.
  if [ "$(( size * 100 / max ))" -ge 95 ]; then
    usage="${usage} (at limit)"
  fi
fi

emit "| ${LABEL} | ${rate}% | ${hit} | ${miss} | ${usage} |"
