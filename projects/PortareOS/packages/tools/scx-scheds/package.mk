# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present PortareOS (https://github.com/portare-ch)

PKG_NAME="scx-scheds"
PKG_VERSION="b2cd800ecc621eb556148a1b1c6b740e71091128"   # v1.1.3
PKG_LICENSE="GPL-2.0"
PKG_SITE="https://github.com/sched-ext/scx"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain cargo:host cargo rust llvm:host elfutils:host zlib:host elfutils zlib"
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

  # vsprintf and libbpf-sys have build.rs scripts, which run on the build
  # machine and so must be compiled for it. cc-rs picks the host compiler up
  # from HOST_CC correctly, but it *appends* the triple-scoped and HOST_
  # variables to plain CFLAGS rather than replacing it, so anything left in
  # CFLAGS reaches every compile it does. With the buildsystem's aarch64
  # CFLAGS in scope, x86_64 gcc was handed -mabi=lp64 and -mtune=cortex-x3.
  # Setting HOST_CFLAGS does not help; it only adds host flags after the
  # target ones. CFLAGS has to be empty, with the target flags reaching the
  # target compile through its own triple-scoped variable. Build scripts then
  # compile with cc-rs defaults, which is what they want anyway.
  export CFLAGS_${TARGET_NAME//-/_}="${CFLAGS}"
  export CXXFLAGS_${TARGET_NAME//-/_}="${CXXFLAGS}"
  unset CFLAGS CXXFLAGS

  # Same problem one layer down. libbpf's Makefile takes its include flags from
  # pkg-config:
  #     ALL_CFLAGS += $(shell $(PKG_CONFIG) --cflags libelf zlib)
  # and the buildsystem points pkg-config at the aarch64 sysroot for the whole
  # target build. libbpf-sys is a *build* dependency here: it compiles libbpf
  # with the host compiler so libbpf-cargo can generate the BPF skeletons. So
  # an x86_64 compile was handed -I<target sysroot>/usr/include, which shadows
  # /usr/include and gave it the aarch64 linux/ptrace.h - hence "invalid use of
  # undefined type 'struct pt_regs'" on the x86_64 register table.
  #
  # Nothing in this cargo build resolves C for the target through pkg-config;
  # no aarch64 lookups appear anywhere in the build log. So pkg-config goes
  # back to host defaults for this invocation.
  unset PKG_CONFIG_LIBDIR PKG_CONFIG_PATH PKG_CONFIG_SYSROOT_DIR PKG_CONFIG_SYSROOT_BASE

  # scx_utils and scx_arena have build scripts that link libbpf-sys, which
  # always emits "-lelf -lz" for that host link and searches only its own out
  # dir. The container has neither development library, only the runtime
  # libelf.so.1 that dwarves drags in, so the link failed with "cannot find
  # -lelf". The toolchain has both, from elfutils:host and zlib:host, and
  # libbpf-sys takes extra search paths from LIBBPF_SYS_LIBRARY_PATH.
  #
  # Only the static archives are exposed, deliberately. The toolchain's
  # elfutils (0.195) is newer than the container's (0.190), and cargo does not
  # put this path on LD_LIBRARY_PATH when it runs the build script, so one
  # linked against the newer libelf.so would load the older one at runtime and
  # trip over versioned symbols. Linking libelf.a and libz.a leaves nothing to
  # resolve at runtime at all.
  local hostlibs="${PKG_BUILD}/.host-static-libs"
  mkdir -p "${hostlibs}"
  for lib in libelf.a libz.a; do
    [ -f "${TOOLCHAIN}/lib/${lib}" ] || die "scx-scheds: ${TOOLCHAIN}/lib/${lib} is missing - elfutils:host or zlib:host did not install a static library"
    ln -sf "${TOOLCHAIN}/lib/${lib}" "${hostlibs}/${lib}"
  done
  export LIBBPF_SYS_LIBRARY_PATH="${hostlibs}"

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
