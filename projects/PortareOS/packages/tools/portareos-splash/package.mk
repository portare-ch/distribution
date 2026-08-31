# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="portareos-splash"
PKG_VERSION="9d295bcb74be2282e32c6b614efbea6036974ba8"
PKG_SHA256="ffa718a9bbcbf69857b91acf854abaf4cc00a7802f61d531341517546c26e635"
PKG_LICENSE="GPL"
PKG_SITE="https://rocknix.org"
# The upstream repository is ROCKNIX/rocknix-splash. This used to interpolate
# ${PKG_NAME}, which resolved correctly while the package was called
# rocknix-splash and started pointing at a repository that does not exist the
# moment it was renamed. Spelled out so the package name and the upstream name
# can differ.
PKG_URL="https://github.com/ROCKNIX/rocknix-splash/archive/${PKG_VERSION}.tar.gz"
# The tarball unpacks to rocknix-splash-<sha>, and unpack only auto-detects
# ${PKG_NAME}-${PKG_VERSION}. SOURCE_NAME also keeps the cached and mirrored
# filename matching what distribution-sources actually holds.
PKG_SOURCE_NAME="rocknix-splash-${PKG_VERSION}.tar.gz"
PKG_SOURCE_DIR="rocknix-splash-${PKG_VERSION}"
PKG_DEPENDS_INIT="toolchain"
PKG_LONGDESC="PortareOS splash screen application"
