# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

PKG_NAME="scx-scheds"
PKG_VERSION="b2cd800ecc621eb556148a1b1c6b740e71091128"   # v1.1.3
PKG_LICENSE="GPL-2.0"
PKG_SITE="https://github.com/sched-ext/scx"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain cargo:host cargo rust llvm:host elfutils zlib"
PKG_LONGDESC="scx_lavd, the latency-aware sched_ext scheduler, for the Nova's big.LITTLE layout."
PKG_TOOLCHAIN="manual"

# Only scx_lavd is built. The repository carries around thirty schedulers and
# we want one; -p keeps the other twenty-nine out of the build.
make_target() {
  # The BPF objects are compiled to BPF bytecode by the *host* clang, not by
  # the aarch64 cross compiler. llvm:host builds clang (see its
  # PKG_CMAKE_OPTS_HOST, -DLLVM_ENABLE_PROJECTS='clang').
  export BPF_CLANG="${TOOLCHAIN}/bin/clang"

  # scx_cargo reads the arch out of TARGET and maps it through its ARCH_MAP to
  # the kernel's __TARGET_ARCH_* define. It splits on the first '-', so our
  # aarch64-portareos-linux-gnu tuple resolves to aarch64 -> arm64 correctly
  # despite not being a tuple upstream has heard of.
  export CC=${TARGET_NAME}-gcc
  export CXX=${TARGET_NAME}-g++
  export PKG_CONFIG_ALLOW_CROSS=1

  cargo build --release --target ${TARGET_NAME} -p scx_lavd
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -f ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/scx_lavd \
        ${INSTALL}/usr/bin/scx_lavd
  chmod +x ${INSTALL}/usr/bin/scx_lavd

  mkdir -p ${INSTALL}/usr/lib/systemd/system
  cp ${PKG_DIR}/system.d/*.service ${INSTALL}/usr/lib/systemd/system

  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/sources/scx-governor ${INSTALL}/usr/bin
  chmod +x ${INSTALL}/usr/bin/scx-governor
}
