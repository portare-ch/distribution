# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

# Inherit PKG_VERSION, PKG_SHA256 and PKG_URL from the global recipe
# rather than restating them, so this cannot drift behind it again.
# This override exists for daemons/001-ssh, which reads the ssh.enabled
setting and seeds authorized_keys, and for an sshd.service that creates
/storage/.cache/ssh and fixes key permissions before start. The global
recipe already passes --with-keydir=/storage/.cache/ssh and carries the
patch that makes it work, so the build configuration is inherited whole.

--with-ssl-engine is gone with the rest: the global recipe builds
--without, OpenSSL is 3.6 here, and the ENGINE API it enables is
deprecated with nothing on this device using it.
. ${ROOT}/packages/network/openssh/package.mk
PKG_NAME="openssh"
PKG_SITE="https://www.openssh.com/"
PKG_DEPENDS_TARGET="toolchain openssl zlib"
PKG_LONGDESC="An open re-implementation of the SSH package."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="+lto"

PKG_CONFIGURE_OPTS_TARGET="ac_cv_header_rpc_types_h=no \
                           --sysconfdir=/etc/ssh \
                           --libexecdir=/usr/lib/openssh \
                           --disable-strip \
                           --disable-lastlog \
                           --with-sandbox=no \
                           --disable-utmp \
                           --disable-utmpx \
                           --disable-wtmp \
                           --disable-wtmpx \
                           --without-rpath \
                           --with-ssl-engine \
                           --with-privsep-user=nobody \
                           --disable-pututline \
                           --disable-pututxline \
                           --disable-etc-default-login \
                           --with-keydir=/storage/.cache/ssh \
                           --without-pam"

pre_configure_target() {
  export LD="${CC}"
  export LDFLAGS="${TARGET_CFLAGS} ${TARGET_LDFLAGS}"
}

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/lib/openssh/ssh-keysign
  rm -rf ${INSTALL}/usr/lib/openssh/ssh-pkcs11-helper
  if [ ! ${SFTP_SERVER} = "yes" ]; then
    rm -rf ${INSTALL}/usr/lib/openssh/sftp-server
  fi
  rm -rf ${INSTALL}/usr/bin/ssh-add
  rm -rf ${INSTALL}/usr/bin/ssh-agent
  rm -rf ${INSTALL}/usr/bin/ssh-keyscan

  sed -e "s|^#PermitRootLogin.*|PermitRootLogin yes|g" \
      -e "s|^#StrictModes.*|StrictModes no|g" \
      -i ${INSTALL}/etc/ssh/sshd_config

  debug_strip ${INSTALL}/usr
}

post_install() {
  enable_service sshd.service
}
