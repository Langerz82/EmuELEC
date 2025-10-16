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

SDLJOYTEST="/tmp/jc/sdljoytest.txt"
INPUT_DEVICES="/tmp/jc/devices.txt"

jc_get_device_header() {
  local GUID="${1}"

  local v=${GUID:0:8}
  local bus=$(echo ${v:2:2}${v:0:2}) # Bus, generally not needed
  v=${GUID:8:8}
  local vendor=$(echo ${v:2:2}${v:0:2}) # Vendor
  v=${GUID:16:8}
  local product=$(echo ${v:2:2}${v:0:2}) # Product
  v=${GUID:24:8}
  local version=$(echo ${v:2:2}${v:0:2}) # Version
  echo "^I:.*Bus=${bus} Vendor=${vendor} Product=${product} Version=${version}$"
}

jc_get_device() {
  local I_REGEX=$( jc_get_device_header ${2} )
  for (( pi = ${1}; pi < 9; pi++ )); do
    local EE_DEVICE=$( cat ${INPUT_DEVICES} | grep -Ew -A 5 "$I_REGEX" | grep -E -B 5 "^[ ]*H: Handlers=.*js${pi}.*$" )
    [[ -z "${EE_DEVICE}" ]] && continue
    local EE_NAME=$( echo ${EE_DEVICE} | grep "N: Name=" | cut -d'"' -f2 )
    local EE_JSNUM=$( echo ${EE_DEVICE} | grep "H: Handlers=" |  sed -nE 's|^.*(js[0-9]+).*$|\1|p' )
    echo ${EE_JSNUM} \"${EE_NAME}\"
    return
  done
}

jc_get_config() {
  local JOY_NAME=$( cat ${SDLJOYTEST} | grep "Joystick ${1} name" | cut -d"'" -f2 )
  [[ -z ${JOY_NAME} ]] && return

  local DEVICE_GUID=$( cat ${SDLJOYTEST} | grep "Joystick ${1} Guid" | cut -d" " -f4 )
  [[ -z ${DEVICE_GUID} ]] && return

  local JOYMAPPING=$( cat ${SDLJOYTEST} | grep "mapping: ${DEVICE_GUID}" | cut -d" " -f7- )
  [[ -z ${JOYMAPPING} ]] && return

  local JC_DEVICE=$( jc_get_device ${1} ${DEVICE_GUID} )
  [[ -z ${JC_DEVICE} ]] && return

  local JSI=$( echo ${JC_DEVICE} | cut -d' ' -f1 )
  [[ -z ${JSI} ]] && JSI=js0

  local JOY_UDEVNAME=$( echo ${JC_DEVICE} | cut -d'"' -f2 )

  local PLAYER_CFG="$(( $1 + 1 )) ${JSI} ${DEVICE_GUID} \"${JOY_NAME}\" \"${JOYMAPPING}\" \"${JOY_UDEVNAME}\""
  echo ${PLAYER_CFG}
}

jc_get_players() {
  cat /proc/bus/input/devices > ${INPUT_DEVICES}
  sdljoytest -skip_loop > ${SDLJOYTEST}

  for jci in {0..3}; do
    CFG=$( jc_get_config "${jci}" )
    CFG_CLEAN=${CFG}
    [[ -z "${CFG}" ]] && CFG_CLEAN=$(( $jci + 1 ))
    echo ${CFG}
    eval clean_pad ${CFG_CLEAN}
    [[ ! -z "${CFG}" ]] && eval set_pad ${CFG}
  done
}
