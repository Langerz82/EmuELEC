# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libdrm"
PKG_VERSION="2.4.112"
PKG_SHA256="00b07710bd09b35cd8d80eaf4f4497fe27f4becf467a9830f1f5e8324f8420ff"
PKG_LICENSE="GPL"
PKG_SITE="https://dri.freedesktop.org"
PKG_URL="https://dri.freedesktop.org/libdrm/libdrm-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain libpciaccess"
PKG_LONGDESC="The userspace interface library to kernel DRM services."
PKG_TOOLCHAIN="meson"

get_graphicdrivers

PKG_MESON_OPTS_TARGET="-Dnouveau=false \
                       -Domap=false \
                       -Dexynos=false \
                       -Dtegra=false \
                       -Dcairo-tests=false \
                       -Dman-pages=false \
                       -Dvalgrind=false \
                       -Dfreedreno-kgsl=false \
                       -Dinstall-test-programs=true \
                       -Dudev=false"

listcontains "${GRAPHIC_DRIVERS}" "(crocus|iris|i915|i965)" &&
  PKG_MESON_OPTS_TARGET+=" -Dintel=true" || PKG_MESON_OPTS_TARGET+=" -Dintel=false"

listcontains "${GRAPHIC_DRIVERS}" "(r200|r300|r600|radeonsi)" &&
  PKG_MESON_OPTS_TARGET+=" -Dradeon=true" || PKG_MESON_OPTS_TARGET+=" -Dradeon=false"

listcontains "${GRAPHIC_DRIVERS}" "radeonsi" &&
  PKG_MESON_OPTS_TARGET+=" -Damdgpu=true" || PKG_MESON_OPTS_TARGET+=" -Damdgpu=false"

listcontains "${GRAPHIC_DRIVERS}" "vmware" &&
  PKG_MESON_OPTS_TARGET+=" -Dvmwgfx=true" || PKG_MESON_OPTS_TARGET+=" -Dvmwgfx=false"

listcontains "${GRAPHIC_DRIVERS}" "vc4" &&
  PKG_MESON_OPTS_TARGET+=" -Dvc4=true" || PKG_MESON_OPTS_TARGET+=" -Dvc4=false"

listcontains "${GRAPHIC_DRIVERS}" "freedreno" &&
  PKG_MESON_OPTS_TARGET+=" -Dfreedreno=true" || PKG_MESON_OPTS_TARGET+=" -Dfreedreno=false"

listcontains "${GRAPHIC_DRIVERS}" "etnaviv" &&
  PKG_MESON_OPTS_TARGET+=" -Detnaviv=true" || PKG_MESON_OPTS_TARGET+=" -Detnaviv=false"

listcontains "${GRAPHIC_DRIVERS}" "nouveau" &&
  PKG_MESON_OPTS_TARGET+=" -Dnouveau=true" || PKG_MESON_OPTS_TARGET+=" -Dnouveau=false"

listcontains "${GRAPHIC_DRIVERS}" "freedreno" &&
  PKG_MESON_OPTS_TARGET+=" -Dfreedreno=true" || PKG_MESON_OPTS_TARGET+=" -Dfreedreno=false"

if [ "${DISTRO}" = "Lakka" ]; then
  PKG_MESON_OPTS_TARGET="${PKG_MESON_OPTS_TARGET//-Dlibkms=false/-Dlibkms=true}"
fi

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp -a ${PKG_BUILD}/.${TARGET_NAME}/tests/modetest/modetest ${INSTALL}/usr/bin/
  if [ "$PROJECT" = "L4T" ]; then
    rm ${INSTALL}/usr/lib/libdrm.so.2
  fi

  # Remove all test programs installed by install-test-programs=true except modetest
  # Do not "not use" the ninja install and replace this with a simple "cp modetest"
  # as ninja strips the unnecessary build rpath during the install.
  safe_remove ${INSTALL}/usr/bin/drmdevice
  safe_remove ${INSTALL}/usr/bin/modeprint
  safe_remove ${INSTALL}/usr/bin/proptest
  safe_remove ${INSTALL}/usr/bin/vbltest
}
