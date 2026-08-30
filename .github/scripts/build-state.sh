#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Cross-run build state for the CI stages allowed to build incrementally.
#
# The buildsystem already decides, per package, whether a rebuild is needed:
# scripts/build hashes each package's recipe and patches (calculate_stamp) and
# skips the package when that hash matches the one recorded in
# .stamps/<pkg>/build_<target>. In CI the mechanism never fires, because
# .stamps and install_pkg live only inside the per-run artifacts and the
# purge-artifact job deletes all of them at the end of every build. Every run
# therefore starts with an empty .stamps, every stamp is missing, and every
# package rebuilds. This script gives that mechanism a memory across runs.
#
# The safety problem it has to solve: calculate_stamp hashes a package's own
# files only, and scripts/build returns "already built" before PKG_DEPENDS_* is
# even read, so changing a dependency does not rebuild its dependents.
# Restoring a stage's state blindly would keep emulators that were built
# against a library which has since changed - a green run producing an image
# full of mismatched binaries.
#
# So the restore is gated on the upstream surface. "snapshot" runs after the
# upstream stage artifacts are unpacked and hashes the stamps they brought;
# that is exactly the set of dependency recipes this stage is about to build
# against. The saved archive records the same digest from the run that produced
# it, and the two must match or the archive is ignored and the stage builds
# cold. Edit SDL2 and its stamp content changes, the digests diverge, and every
# dependent stage rebuilds by itself.
#
# "snapshot" also records which install_* entries arrived from upstream, so
# "save" can archive only the packages this stage actually contributes rather
# than a copy of everything its dependencies installed.
#
# Nothing here may fail a build: a missing, truncated or mismatched archive is
# a cold build, never an error.
#
# Usage:
#   build-state.sh snapshot <build-dir>                     # prints the digest
#   build-state.sh restore  <build-dir> <asset-base> <digest>
#   build-state.sh save     <build-dir> <asset-base> <digest>
#
# Environment:
#   CACHE_REPO  owner/repo holding the "ccache" release  (restore only)

set -euo pipefail

DIGEST_FILE=".build-state-digest"
UPSTREAM_LIST=".build-state-upstream-list"
# Enough parts for any archive we produce; each is capped below GitHub's 2 GB
# per-asset limit.
SUFFIXES="aa ab ac ad ae af ag ah ai aj ak al"

# A digest over the stamp files only. They are tiny, and their contents are the
# recorded deephashes, so this changes exactly when some package's recipe
# changed - and not when an unchanged package merely gets rebuilt.
stamp_digest() {
  local build_dir="$1"

  # No stamps at all - nothing upstream to compare against. Emit a value that
  # cannot match any saved digest, so the restore falls back to a cold build.
  # Guarding this also matters mechanically: under "set -o pipefail" a find
  # over a missing directory fails the pipeline and would fail the step.
  if [ ! -d "${build_dir}/.stamps" ]; then
    echo "no-stamps"
    return 0
  fi

  find "${build_dir}/.stamps" -type f -name 'build_*' -print0 2>/dev/null \
    | LC_ALL=C sort -z \
    | xargs -0 -r sha256sum \
    | sha256sum \
    | cut -d' ' -f1
}

# Depth-1 entries of every install_* directory, as they stand right now.
install_entries() {
  local build_dir="$1"
  find "${build_dir}" -maxdepth 1 -type d -name 'install_*' \
    -exec find {} -mindepth 1 -maxdepth 1 \; 2>/dev/null | LC_ALL=C sort
}

cmd_snapshot() {
  local build_dir="$1"
  install_entries "${build_dir}" > "${UPSTREAM_LIST}"
  echo "build-state: $(wc -l < "${UPSTREAM_LIST}") install entries came from upstream." >&2
  stamp_digest "${build_dir}"
}

cmd_restore() {
  local build_dir="$1" asset="$2" want="$3"
  local base="https://github.com/${CACHE_REPO}/releases/download/ccache"
  local n=0 s have

  for s in ${SUFFIXES}; do
    curl -L --fail --silent --show-error -o "${asset}.part-${s}" \
      "${base}/${asset}.part-${s}" || break
    n=$((n + 1))
  done

  if [ "${n}" -eq 0 ]; then
    rm -f "${asset}".part-* 2>/dev/null || true
    echo "build-state: no saved state for ${asset} - building cold."
    return 0
  fi

  cat "${asset}".part-* > state.tar
  rm -f "${asset}".part-*

  if ! tar -xf state.tar "./${DIGEST_FILE}" 2>/dev/null; then
    rm -f state.tar
    echo "build-state: archive carries no digest - building cold."
    return 0
  fi

  have="$(cat "${DIGEST_FILE}")"
  rm -f "${DIGEST_FILE}"

  if [ "${have}" != "${want}" ]; then
    rm -f state.tar
    echo "build-state: upstream changed since this state was saved - building cold."
    echo "  saved against ${have}"
    echo "  now           ${want}"
    return 0
  fi

  # The digests match, so every stamp in the archive is byte-identical to the
  # one the upstream artifacts just delivered; extracting over them is a no-op,
  # and this stage's own stamps and packages come back.
  echo "build-state: upstream unchanged - restoring ${asset}."
  tar -xf state.tar || echo "build-state: extract failed - building cold."
  rm -f state.tar
  echo "build-state: $(find "${build_dir}/.stamps" -type f -name 'build_*' 2>/dev/null | wc -l) stamps now present."
}

cmd_save() {
  local build_dir="$1" asset="$2" digest="$3"
  local list=".build-state-save-list"

  # Everything installed that did not come from upstream is ours: what this
  # stage built this run, plus whatever a restore brought back.
  if [ -f "${UPSTREAM_LIST}" ]; then
    install_entries "${build_dir}" | LC_ALL=C comm -23 - "${UPSTREAM_LIST}" > "${list}"
  else
    echo "build-state: no upstream snapshot - saving every install entry." >&2
    install_entries "${build_dir}" > "${list}"
  fi

  printf '%s\n' "${digest}" > "${DIGEST_FILE}"
  printf '%s\n' "./${DIGEST_FILE}" >> "${list}"
  printf '%s\n' "${build_dir}/.stamps" >> "${list}"

  echo "build-state: archiving $(wc -l < "${list}") paths."
  tar -cf - -T "${list}" | split -b 1900m - "${asset}.part-"
  rm -f "${DIGEST_FILE}" "${list}"
  ls -la "${asset}".part-*
}

case "${1:-}" in
  snapshot) shift; cmd_snapshot "$@" ;;
  restore)  shift; cmd_restore  "$@" ;;
  save)     shift; cmd_save     "$@" ;;
  *) echo "usage: build-state.sh {snapshot|restore|save} ..." >&2; exit 2 ;;
esac
