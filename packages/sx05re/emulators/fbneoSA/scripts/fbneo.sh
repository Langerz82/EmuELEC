#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

mkdir -p /emuelec/configs/fbneo
mkdir -p /storage/.local/share

if [ -d "/storage/.local/share/fbneo/" ]; then
    mv -f /storage/.local/share/fbneo/* /emuelec/configs/fbneo
    rm -rf /storage/.local/share/fbneo
    ln -sf /emuelec/configs/fbneo /storage/.local/share/fbneo
fi

if [ ! -L "/storage/.local/share/fbneo" ]; then
    ln -sf /emuelec/configs/fbneo /storage/.local/share/fbneo
fi

# TODO: Allow settings from ES 
#case "$@" in
#EXTRAOPTS=

if [ "${3}" == "NCD" ]; then
    echo . > /dev/null
    #EXTRAOPTS=CDOPTS?
fi

PLATFORM="${1}"
ROMFILE=$(basename -- "${2}")
ROM="${ROMFILE%.*}"
DIR=$(dirname ${2})

sed -i "s|szAppRomPaths\[0\].*|szAppRomPaths\[0\] ${DIR}/|" /emuelec/configs/fbneo/config/fbneo.ini

export LIBGL_NOBANNER=1
export LIBGL_SILENTSTUB=1

AUTOGP=$(get_ee_setting fbneosa_auto_gamepad)
[[ "${AUTOGP}" == "1" ]] && set_fbneo_joy.sh "${PLATFORM}" "${ROMFILE}"

[[ "${EE_DEVICE}" == "Amlogic-ng" ]] && fbfix
fbneo -joy -fullscreen "${ROM}" ${EXTRAOPTS} >> /emuelec/logs/emuelec.log 2>&1
