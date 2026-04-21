#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

. /etc/profile

ROMSPPSSPPFOLDER=/storage/roms/savestates/PPSSPPSDL/PSP
PPSSPPFOLDER=/emuelec/configs/ppsspp/PSP
AUTOGP=$(get_ee_setting ppssppsdl_auto_gamepad)
CHEEVOS=$(get_ee_setting global.retroachievements)


if [[ "${AUTOGP}" == "1" ]]; then
	set_ppsspp_joy.sh
fi

if [[ "${CHEEVOS}" == "1" ]]; then
	ppssppcheevos.sh
fi

if [ -d "/storage/.config/ppsspp" ]; then
	mv -f /storage/.config/ppsspp /emuelec/configs
fi

# Make sure we have the correct symlinks
for dir in Cheats PPSSPP_STATE SAVEDATA TEXTURES; do
    mkdir -p "${ROMSPPSSPPFOLDER}"

   if [ ! -L ${PPSSPPFOLDER}/${dir} ]; then
		cp -rf ${PPSSPPFOLDER}/${dir}/. ${ROMSPPSSPPFOLDER}/${dir}/
		rm -rf ${PPSSPPFOLDER}/${dir}
		ln -sf ${ROMSPPSSPPFOLDER}/${dir} ${PPSSPPFOLDER}/${dir}
    fi
done

if [ ! -s "${ROMSPPSSPPFOLDER}/Cheats/cheat.db" ];then
	mkdir -p "${ROMSPPSSPPFOLDER}/Cheats/"
	cp -rf /usr/config/emuelec/configs/ppsspp/PSP/SYSTEM/Cheats/. "${ROMSPPSSPPFOLDER}/Cheats/"

	CHEAT_DB_VERSION="06d4d6148b66109005f7d51c37e8344f0bc042cc"
	curl -sLo "${ROMSPPSSPPFOLDER}/Cheats/cheat.db" -f "https://raw.githubusercontent.com/Saramagrean/CWCheat-Database-Plus-/${CHEAT_DB_VERSION}/cheat.db" || true
fi

ARG=${1//[\\]/}
export SDL_AUDIODRIVER=alsa
PPSSPPSDL --fullscreen "${ARG}"
