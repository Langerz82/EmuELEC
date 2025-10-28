#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present Joshua L (https://github.com/Langerz82)

# 08/01/23 - Joshua L - Modified get GUID thanks to shantigilbert.
# 16/10/25 - Joshua L - Modified uses sdljoytest.

# Source predefined functions and variables
. /etc/profile

GCDB="${SDL_GAMECONTROLLERCONFIG_FILE}"

EMULATOR="${1}"

mkdir -p "/tmp/jc"

GAMEPAD_INFO_ALL="/tmp/jc/gamepad_info.txt"

jc_get_config() {
  local GP_FILE="/tmp/jc/js${1}"
  cat ${GAMEPAD_INFO_ALL} | grep -E -A5 "^Gamepad js${1}$" > ${GP_FILE}
  [[ -z ${GP_FILE} ]] && echo ' ' && return

  local JOY_UDEVNAME=$( cat ${GP_FILE} | grep -P "^UDEV name:.*" | cut -c18- )
  local JOY_NAME=$( cat ${GP_FILE} | grep -P "^SDL name:.*" | cut -c18- )
  local DEVICE_GUID=$( cat ${GP_FILE} | grep -P "^SDL GUID:.*" | cut -c18- )
  local JOYMAPPING=$( cat ${GP_FILE} | grep -P "^Mapping:.*" | cut -c18- )
  local INSTANCE_ID=$( cat ${GP_FILE} | grep -P "^Instance ID:.*" | cut -c18- )

  echo $(( $1 + 1 )) js${1} ${DEVICE_GUID} \"${JOY_NAME}\" \"${JOYMAPPING}\" \"${JOY_UDEVNAME}\"
}

jc_get_players() {
  gamepad_info -more > ${GAMEPAD_INFO_ALL}

  for jci in {0..3}; do
    CFG=$( jc_get_config "${jci}" )
    CFG_CLEAN=${CFG}
    [[ -z "${CFG}" ]] && CFG_CLEAN=$(( $jci + 1 ))
    echo ${CFG}
    eval clean_pad ${CFG_CLEAN}
    [[ ! -z "${CFG}" ]] && eval set_pad ${CFG}
  done
}
