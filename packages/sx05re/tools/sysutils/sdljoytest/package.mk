# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="sdljoytest"
PKG_VERSION="49724c185e19d176cb05f08eab5f2349c4c365b7"
PKG_SHA256="e6c321cfb33b040dc56aa1472df6f50f5c956446e765e0238b073da4e6774ab1"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/EmuELEC/sdljoytest"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_LONGDESC="Test joystick with SDL2 in Linux"
PKG_TOOLCHAIN="make"

pre_configure_target() {
sed -i "s|gcc|${CC}|" Makefile
}

makeinstall_target() {
mkdir -p ${INSTALL}/usr/bin
cp -rf test_gamepad_SDL2 ${INSTALL}/usr/bin/sdljoytest
cp -rf map_gamepad_SDL2 ${INSTALL}/usr/bin/sdljoymap
cp -rf gamepad_info ${INSTALL}/usr/bin/gamepad_info
cp -rf sdl_ra_joystick_map ${INSTALL}/usr/bin/sdl_ra_joystick_map
}
