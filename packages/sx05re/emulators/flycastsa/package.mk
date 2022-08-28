# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="flycastsa"
PKG_VERSION="7457db8bba3277dcc9b4ec0c3556847f5082a455"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/flyinghead/flycast"
PKG_URL="$PKG_SITE.git"
PKG_DEPENDS_TARGET="toolchain $OPENGLES alsa SDL2 libzip zip"
PKG_LONGDESC="Flycast is a multiplatform Sega Dreamcast, Naomi and Atomiswave emulator"
PKG_TOOLCHAIN="cmake"
PKG_GIT_CLONE_BRANCH="master"

if [ "${ARCH}" == "arm" ]; then
	PKG_PATCH_DIRS="arm"
fi

pre_configure_target() {
if [ ! "${OPENGLES}" = "" ]; then
	PKG_CMAKE_OPTS_TARGET+="-DUSE_GLES=ON -DUSE_VULKAN=OFF"
else
	PKG_DEPENDS_TARGET+=" ${OPENGL}"
	PKG_CMAKE_OPTS_TARGET+="-DUSE_OPENGL=ON -DUSE_GLES=OFF -USE_GLES2=OFF -DUSE_VULKAN=OFF"
fi

	export CXXFLAGS="${CXXFLAGS} -Wno-error=array-bounds"
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/bin
  cp $PKG_BUILD/.${TARGET_NAME}/flycast $INSTALL/usr/bin/flycast
  cp $PKG_DIR/scripts/* $INSTALL/usr/bin

	chmod +x $INSTALL/usr/bin/flycast.sh
	chmod +x $INSTALL/usr/bin/set_flycast_joy.sh
}
