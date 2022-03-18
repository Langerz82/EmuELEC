# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="u-boot"
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://www.denx.de/wiki/U-Boot"
PKG_DEPENDS_TARGET="toolchain swig:host"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems."

PKG_IS_KERNEL_PKG="yes"
PKG_STAMP="$UBOOT_SYSTEM"

[ -n "$ATF_PLATFORM" ] && PKG_DEPENDS_TARGET+=" atf"

PKG_NEED_UNPACK="$PROJECT_DIR/$PROJECT/bootloader"
[ -n "$DEVICE" ] && PKG_NEED_UNPACK+=" $PROJECT_DIR/$PROJECT/devices/$DEVICE/bootloader"

case "$PROJECT" in
  Rockchip)
  if [ "$DEVICE" == "OdroidGoAdvance" ]; then
  	# This is specific for the Rk3326 Odroid Go Advance/Super
    PKG_VERSION="0e26e35cb18a80005b7de45c95858c86a2f7f41e"
    PKG_SHA256="0e0939ba2fdb68dba26dca759092e63d4a63c43068af97deccbb2609e9675485"
    PKG_URL="https://github.com/hardkernel/u-boot/archive/$PKG_VERSION.tar.gz"
    PKG_PATCH_DIRS="OdroidGoAdvance"
  elif [ "$DEVICE" == "GameForce" ]; then
  	# This is specific for the Rk3326 GameForce Chi
    PKG_VERSION="3f696081df4f44ef2ccfe2d7033889607bb7dd45"
    PKG_SHA256="e192e74f708f93cbeabdb7c5c1fbc6e49b5b2e036ad484f5aecf19e03cfabc9e"
    PKG_URL="https://github.com/shantigilbert/u-boot/archive/$PKG_VERSION.tar.gz"
	PKG_PATCH_DIRS="GameForce"
  elif [ "$DEVICE" == "RK356x" ]; then
  	# This is specific for the Rk3568
    # new version, does not boot
     PKG_VERSION="5961c0c398a4208da5bf4704d4fb081c6563a756"
     PKG_SHA256="f81a0225b7c31e23ba3f0b6f91ff39e322a60af9c4c5403a717502ad5f807abd"
    
    # old working
    # PKG_VERSION="1f7d2c1f6bd75028c9a95de89426ad7e0eeb2394"
    # PKG_SHA256="2f88c83e7d7d287cc0abf9a79de64475d174511a2d8ccd16d96ed23e83c50a26"
    
    PKG_URL="https://gitlab.com/firefly-linux/u-boot/-/archive/$PKG_VERSION/u-boot-$PKG_VERSION.tar.gz"
	PKG_PATCH_DIRS="RK356x"
  else
    PKG_VERSION="8659d08d2b589693d121c1298484e861b7dafc4f"
    PKG_SHA256="3f9f2bbd0c28be6d7d6eb909823fee5728da023aca0ce37aef3c8f67d1179ec1"
    PKG_URL="https://github.com/rockchip-linux/u-boot/archive/$PKG_VERSION.tar.gz"
    PKG_PATCH_DIRS="rockchip"
  fi
    PKG_DEPENDS_TARGET+=" rkbin"
    PKG_NEED_UNPACK+=" $(get_pkg_directory rkbin)"
    ;;
  *)
    PKG_VERSION="2019.04"
    PKG_SHA256="76b7772d156b3ddd7644c8a1736081e55b78828537ff714065d21dbade229bef"
    PKG_URL="http://ftp.denx.de/pub/u-boot/u-boot-$PKG_VERSION.tar.bz2"
    ;;
esac

post_patch() {
  if [ -n "$UBOOT_SYSTEM" ] && find_file_path bootloader/config; then
    PKG_CONFIG_FILE="$PKG_BUILD/configs/$($ROOT/$SCRIPTS/uboot_helper $PROJECT $DEVICE $UBOOT_SYSTEM config)"
    if [ -f "$PKG_CONFIG_FILE" ]; then
      cat $FOUND_PATH >> "$PKG_CONFIG_FILE"
    fi
  fi
}

make_target() {
export KCFLAGS="-Wno-error=address-of-packed-member"
  if [ -z "$UBOOT_SYSTEM" ]; then
    echo "UBOOT_SYSTEM must be set to build an image"
    echo "see './scripts/uboot_helper' for more information"
  else
   if [ "$DEVICE" != "RK356x" ]; then
    [ "${BUILD_WITH_DEBUG}" = "yes" ] && PKG_DEBUG=1 || PKG_DEBUG=0
    [ -n "$ATF_PLATFORM" ] &&  cp -av $(get_build_dir atf)/bl31.bin .
    DEBUG=${PKG_DEBUG} CROSS_COMPILE="$TARGET_KERNEL_PREFIX" LDFLAGS="" ARCH=arm make mrproper
    DEBUG=${PKG_DEBUG} CROSS_COMPILE="$TARGET_KERNEL_PREFIX" LDFLAGS="" ARCH=arm make $($ROOT/$SCRIPTS/uboot_helper $PROJECT $DEVICE $UBOOT_SYSTEM config)
    DEBUG=${PKG_DEBUG} CROSS_COMPILE="$TARGET_KERNEL_PREFIX" LDFLAGS="" ARCH=arm _python_sysroot="$TOOLCHAIN" _python_prefix=/ _python_exec_prefix=/ make HOSTCC="$HOST_CC" HOSTLDFLAGS="-L$TOOLCHAIN/lib" HOSTSTRIP="true" CONFIG_MKIMAGE_DTC_PATH="scripts/dtc/dtc"
	else
	# This is WIP
#		sed -i "s|TOOLCHAIN_ARM64=.*|TOOLCHAIN_ARM64=${TOOLCHAIN}/bin|" make.sh
#		sed -i "s|aarch64-linux-gnu|${TARGET_NAME}|g" make.sh
#		sed -i "s|../rkbin|$(get_build_dir rkbin)|" make.sh
#		sed -i "s|../rkbin|$(get_build_dir rkbin)|" scripts/fit.sh
#		cd $PKG_BUILD
#		./make.sh $($ROOT/$SCRIPTS/uboot_helper $PROJECT $DEVICE $UBOOT_SYSTEM config | sed "s|_defconfig||")
#		./make.sh --idblock
#		sed -i "s|PATH=bin/rk35/|PATH=$(get_build_dir rkbin)/bin/rk35/|g" $(get_build_dir rkbin)/RKTRUST/RK3568TRUST.ini
#		sed -i "s|1=bin/rk35/|1=$(get_build_dir rkbin)/bin/rk35/|g" $(get_build_dir rkbin)/RKBOOT/RK3568MINIALL.ini 
		
#		$(get_build_dir rkbin)/tools/trust_merger --verbose $(get_build_dir rkbin)/RKTRUST/RK3568TRUST.ini
#      # ./make.sh trust $(get_build_dir rkbin)/RKTRUST/RK3568TRUST.ini
#		./make.sh loader $(get_build_dir rkbin)/RKBOOT/RK3568MINIALL.ini 


# For: 
    # PKG_VERSION="5961c0c398a4208da5bf4704d4fb081c6563a756"
    # PKG_SHA256="f81a0225b7c31e23ba3f0b6f91ff39e322a60af9c4c5403a717502ad5f807abd"
   
		sed -i "s|CROSS_COMPILE_ARM64=\..*|CROSS_COMPILE_ARM64=${TOOLCHAIN}/bin/${TARGET_NAME}-|" make.sh
		sed -i "s|aarch64-linux-gnu|${TARGET_NAME}|g" make.sh
		#sed -i "s|\${TOOLCHAIN}|\${TOOLCHAIN_CC}|g" make.sh
		#sed -i "s|TOOLCHAIN=|TOOLCHAIN_CC=|g" make.sh

		 sed -i "s|PATH\=$(get_build_dir rkbin)/bin/rk35/|PATH\=bin/rk35/|g" $(get_build_dir rkbin)/RKTRUST/RK3568TRUST.ini
		 sed -i "s|1\=$(get_build_dir rkbin)/bin/rk35/|1\=bin/rk35/|g" $(get_build_dir rkbin)/RKBOOT/RK3568MINIALL.ini 


		sed -i "s|python2|python3|g" make.sh
		sed -i "s|\.\./rkbin|$(get_build_dir rkbin)|" make.sh
		sed -i "s|\.\./rkbin|$(get_build_dir rkbin)|" scripts/fit.sh
		cd $PKG_BUILD
		./make.sh $($ROOT/$SCRIPTS/uboot_helper $PROJECT $DEVICE $UBOOT_SYSTEM config | sed "s|_defconfig||")
		./make.sh --idblock
		# ./scripts/fit.sh --ini-trust $(get_build_dir rkbin)/RKTRUST/RK3568TRUST.ini --ini-loader $(get_build_dir rkbin)/RKBOOT/RK3568MINIALL.ini --chip RK3568
		 
		 sed -i "s|PATH\=bin/rk35/|PATH\=$(get_build_dir rkbin)/bin/rk35/|g" $(get_build_dir rkbin)/RKTRUST/RK3568TRUST.ini
		 sed -i "s|1\=bin/rk35/|1\=$(get_build_dir rkbin)/bin/rk35/|g" $(get_build_dir rkbin)/RKBOOT/RK3568MINIALL.ini 
		 
		 $(get_build_dir rkbin)/tools/trust_merger --verbose $(get_build_dir rkbin)/RKTRUST/RK3568TRUST.ini
		 #./make.sh trust $(get_build_dir rkbin)/RKTRUST/RK3568TRUST.ini
		./make.sh loader $(get_build_dir rkbin)/RKBOOT/RK3568MINIALL.ini 

# TEMP!!!!! WE USE PRECOMPILED U-BOOT UNTIL WE CAN FIND A FIX
	echo "TEMP!!!!! WE USE PRECOMPILED U-BOOT UNTIL WE CAN FIND A FIX"
	echo "TEMP!!!!! WE USE PRECOMPILED U-BOOT UNTIL WE CAN FIND A FIX"
	echo "TEMP!!!!! WE USE PRECOMPILED U-BOOT UNTIL WE CAN FIND A FIX"
	echo "TEMP!!!!! WE USE PRECOMPILED U-BOOT UNTIL WE CAN FIND A FIX"
	echo "TEMP!!!!! WE USE PRECOMPILED U-BOOT UNTIL WE CAN FIND A FIX"
	echo "TEMP!!!!! WE USE PRECOMPILED U-BOOT UNTIL WE CAN FIND A FIX"
	cp -av $PKG_DIR/imgs/uboot.img $PKG_BUILD

	fi
  fi
}


makeinstall_target() {
  mkdir -p $INSTALL/usr/share/bootloader

    # Only install u-boot.img et al when building a board specific image
    if [ -n "$UBOOT_SYSTEM" ]; then
      find_file_path bootloader/install && . ${FOUND_PATH}
    fi

    # Always install the update script
    find_file_path bootloader/update.sh && cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader

    # Always install the canupdate script
    if find_file_path bootloader/canupdate.sh; then
      cp -av ${FOUND_PATH} $INSTALL/usr/share/bootloader
      sed -e "s/@PROJECT@/${DEVICE:-$PROJECT}/g" \
          -i $INSTALL/usr/share/bootloader/canupdate.sh
    fi
}
