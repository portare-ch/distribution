# Ubuntu 26.04. The package set follows tools/docker/resolute/Dockerfile,
# upstream's recipe for this base: go 1.26 rather than 1.23, and libcrypt-dev,
# which 26.04 split out of libc6-dev.
#
# The compiler does not. Upstream picks gcc-16, and 26.04 ships that as an
# experimental trunk snapshot, "16.0.1 20260322 (experimental)", which has no
# business bootstrapping a cross toolchain. gcc-15 is released, is in the same
# archive, and is the major version the buildsystem builds for the target
# anyway.
#
# The host compiler still moves 12 to 15, and that is the part to watch rather
# than the base image: it compiles the target gcc and every host tool.
FROM ubuntu:resolute

ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/usr/bin/bash", "-c"]

RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install -y locales sudo

RUN locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# useradd, not adduser: the ubuntu container image ships only priority-required
# packages, and adduser is priority-important, so it is not there. useradd comes
# from passwd, which is required and therefore always present.
RUN useradd docker -U -G sudo -m -s /bin/bash \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN apt-get update \
 && apt-get install -y \
    ca-certificates curl bash bc gcc-15 cpp-15 sed patch patchutils tar bzip2 gzip xz-utils zstd perl gawk gperf zip \
      unzip diffutils lzop make file g++-15 xfonts-utils xsltproc python3 \
      libc6-dev libcrypt-dev libncurses-dev libjson-perl libxml-parser-perl libparse-yapp-perl rdfind \
      golang-1.26-go git openssh-client rsync upx-ucl \
      python-is-python3 python3 parted wget xxd automake xmlstarlet rsync \
      dwarves \
    --no-install-recommends \
    && ln -s /usr/lib/go-1.26 /usr/lib/go \
    && ln -s /usr/lib/go-1.26/bin/go /usr/bin/go \
    && ln -s /usr/lib/go-1.26/bin/gofmt /usr/bin/gofmt

RUN if [ "$(uname -m)" = "aarch64" ]; then \
  apt-get install -y libc6-amd64-cross qemu-user-binfmt --no-install-recommends; \
 fi

RUN rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 100 \
    --slave /usr/bin/cpp cpp /usr/bin/cpp-15 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-15 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-15
RUN update-alternatives --config gcc

RUN mkdir -p /nix && chown docker /nix && chmod 777 /nix
RUN mkdir -p /work && chown docker /work

WORKDIR /work

USER docker
