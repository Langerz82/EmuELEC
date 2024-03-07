# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present EmuELEC (https://github.com/EmuELEC)

PKG_NAME="gzdoom"
PKG_VERSION="425cc72b1f701e7b93bdeb1936c4e37875ccb5d4"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/dhwz/gzdoom"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_HOST="toolchain zmusic:host libwebp:host"
PKG_DEPENDS_TARGET="toolchain SDL2 gzdoom:host zmusic libwebp"
PKG_LONGDESC="GZDoom is a modder-friendly OpenGL and Vulkan source port based on the DOOM engine"
PKG_TOOLCHAIN="cmake-make"

pre_build_host() {
  HOST_CMAKE_OPTS=""
}

make_host() {
  cmake . -DNO_GTK=ON
  make
}

makeinstall_host() {
: #no
}

pre_configure_host(){
PKG_CMAKE_OPTS_HOST=" -DZMUSIC_LIBRARIES=$(get_build_dir zmusic)/build_host/source/libzmusic.so \
                      -DZMUSIC_INCLUDE_DIR=$(get_build_dir zmusic)/include \
                      -DCMAKE_BUILD_TYPE=Release \
                      -DCMAKE_RULE_MESSAGES=OFF \
                      -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"
}

pre_configure_target() {
PKG_CMAKE_OPTS_TARGET=" -DNO_GTK=ON \
                        -DFORCE_CROSSCOMPILE=ON \
                        -DIMPORT_EXECUTABLES=${PKG_BUILD}/.${HOST_NAME}/ImportExecutables.cmake \
                        -DCMAKE_BUILD_TYPE=Release \
                        -DCMAKE_RULE_MESSAGES=OFF \
                        -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
                        -DHAVE_GLES2=ON \
                        -DHAVE_VULKAN=OFF \
                        -DZMUSIC_LIBRARIES=$(get_build_dir zmusic)/build_target/source/libzmusic.so -DZMUSIC_INCLUDE_DIR=$(get_build_dir zmusic)/include"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/scripts/gzdoom.sh ${INSTALL}/usr/bin/
  cp ${PKG_BUILD}/.${TARGET_NAME}/gzdoom ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/config/emuelec/configs/gzdoom
  if [ "$DEVICE" == "OdroidGoAdvance" ] || [ "$DEVICE" == "GameForce" ]; then
    cp ${PKG_DIR}/config/OGA/* ${INSTALL}/usr/config/emuelec/configs/gzdoom
  else
    cp ${PKG_DIR}/config/N2/* ${INSTALL}/usr/config/emuelec/configs/gzdoom
  fi
  cp ${PKG_BUILD}/.${TARGET_NAME}/*.pk3 ${INSTALL}/usr/config/emuelec/configs/gzdoom
  cp -r ${PKG_BUILD}/.${TARGET_NAME}/soundfonts ${INSTALL}/usr/config/emuelec/configs/gzdoom
  cp -r ${PKG_BUILD}/.${TARGET_NAME}/fm_banks ${INSTALL}/usr/config/emuelec/configs/gzdoom
}
