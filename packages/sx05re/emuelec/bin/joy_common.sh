#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present Joshua L (https://github.com/Langerz82)

# 08/01/23 - Joshua L - Modified get GUID thanks to shantigilbert.
# 16/10/25 - Joshua L - Modified uses sdljoytest.
# 22/02/26 - Joshua L - Added js instance ID.
# 23/02/26 - Pablo S - Added ES Ordering fixes. (https://github.com/pmsobrado)

# Source predefined functions and variables
. /etc/profile

GCDB="${SDL_GAMECONTROLLERCONFIG_FILE}"

EMULATOR="${1}"

FIXED_ORDER=0
[[ "${2}" == "fixed_order" ]] && FIXED_ORDER=1

mkdir -p "/tmp/jc"

GAMEPAD_INFO_ALL="/tmp/jc/gamepad_info.txt"

CONTROLLERS_PRIORITY_DATA=
[[ -f "/tmp/controllerconfig.txt" ]] && CONTROLLERS_PRIORITY_DATA=$(cat "/tmp/controllerconfig.txt")

jc_wipe_config_sub_heading() {
    local config_file="$1"
    local sub_heading="$2"
    local tmp_file="$3"

    shift
    shift
    shift

    declare -a array_ref=("$@")

    [[ -f "${tmp_file}" ]] && rm "${tmp_file}"
    local LN=1
    local START_LN=-1
    [[ ! -f "${config_file}" ]] && return
    local REGEX_SUB_HEADING='^\[.+\]$'
    local SUB_HEADING_ACTIVE=0
    while read -r line; do
      if [[ "${line}" =~ $REGEX_SUB_HEADING ]]; then
        if [[ "${line}" == "${sub_heading}" ]]; then
          START_LN=${LN}
          SUB_HEADING_ACTIVE=1
        else
          [[ ${START_LN} != -1 ]] && break
        fi
      fi
      LN=$(( LN + 1 ))
      if [[ "${SUB_HEADING_ACTIVE}" == 1 ]]; then
        for item in "${array_ref[@]}"; do
          local rx="^${item}\ *\=.+$"
          [[ "${line}" =~ ${rx} ]] && echo "${line}" >> ${tmp_file}
        done
      fi
    done < ${config_file}
    if [[ ${START_LN} != -1 ]]; then
      sed -i "${START_LN},$(( LN-1 ))d" "${config_file}"
    fi
}

jc_set_record() {
  local FILE=$1
  local HEADER=$2
  local KEY=$3
  local VALUE=$4

  local rec=$( cat "${FILE}" | grep -e "^${KEY} *= *.*$" )
  if [[ -z "${rec}" ]]; then
    sed -i "/${HEADER}/a ${KEY} = ${RUMBLE}" "${EMU_FILE}"
  else
    sed -i "s/^${KEY} *= *.*$/${KEY} = ${VALUE}/g" "${EMU_FILE}"
  fi
}

jc_get_config() {
  local GAMEPAD_DATA=$(cat ${GAMEPAD_INFO_ALL} | grep -E -A6 "^Gamepad ${1}$")
  [[ -z "${GAMEPAD_DATA}" ]] && echo '' && return

  mapfile -t GAMEPAD_INFO < <(echo "${GAMEPAD_DATA}")

  local JOY_UDEV_NAME="$( echo "${GAMEPAD_INFO[1]}" | cut -c18- )"
  local JOY_SDL_NAME="$( echo "${GAMEPAD_INFO[2]}" | cut -c18- )"
  local DEVICE_GUID="$( echo "${GAMEPAD_INFO[3]}" | cut -c18- )"
  local JOYMAPPING="$( echo "${GAMEPAD_INFO[4]}" | cut -c18- )"
  local INSTANCE_ID="$( echo "${GAMEPAD_INFO[5]}" | cut -c18- )"
  local JS_INDEX="$( echo "${GAMEPAD_INFO[6]}" | cut -c18- )"

  echo js${JS_INDEX} ${DEVICE_GUID} \"${JOY_UDEV_NAME}\" \"${JOYMAPPING}\" \"${JOY_SDL_NAME}\"
}

jc_get_order_indexes() {
  local MAX_VALUE=$1
  shift
  local GUIDS=(${@})
  local PLAYER_ORDER=()
  for i in {0..3}; do
    local CURRENT_GUID=${GUIDS[${i}]}
    local PINDEX=

    # 1. Get player for this physical index (jci)
    if [[ ! -z "${CURRENT_GUID}" ]] && [[ ! -z "${CONTROLLERS_PRIORITY_DATA}" ]]; then
      local priority_record=$( echo "${CONTROLLERS_PRIORITY_DATA}" | grep -o "\-p[1-4]index [0-9] -p[1-4]guid ${CURRENT_GUID}" | head -n1 )
      if [[ ! -z "${priority_record}" ]]; then
        CONTROLLERS_PRIORITY_DATA=$( echo $CONTROLLERS_PRIORITY_DATA | sed "s/${priority_record}//g" )
        PINDEX=$(echo "${priority_record}" | cut -c3 )
        [[ -n "${PINDEX}" ]] && PINDEX=$(( PINDEX - 1 ))
      fi
    fi

    # 2. If it does not exist on the priority settings, assign default one but respecting reserved joypad slots
    if [[ ! -n "${PINDEX}" ]]; then
      for (( i = 0; i < MAX_VALUE; i++ ))
      do
        PINDEX=$i
        [[ ! " ${PLAYER_ORDER[@]} " =~ " ${PINDEX} " ]] && break
      done
    fi
    PLAYER_ORDER+=("${PINDEX}")
  done
  echo "${PLAYER_ORDER[@]}"
}

jc_get_players() {
  gamepad_info -more > ${GAMEPAD_INFO_ALL}

  declare -a player_cfgs=()
  declare -a player_guids=()

  for i in {0..3}; do
    local CFG=$( jc_get_config "${i}" )
    local GUID=$(echo "${CFG}" | awk '{print $2}')

    [[ ! -z "${GUID}" ]] && player_guids+=("${GUID}")
    player_cfgs+=("${CFG}")
  done

  local player_order=(0 1 2 3)
  if [[ "${FIXED_ORDER}" == "0" ]]; then
    player_order=($( jc_get_order_indexes 4 "${player_guids[@]}"))
  fi

  for i in {0..3}; do
      local pi=$(( i + 1 ))
      clean_pad ${pi}
      local order=${player_order[${i}]}
      local cfg=${player_cfgs[${order}]}
      [[ ! -z "${cfg}" ]] && eval set_pad ${pi} ${cfg} ${order}
  done
}
