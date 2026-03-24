#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

CONFIG_DIR="/storage/.config/flycast"
EMU_FILE="${CONFIG_DIR}/emu.cfg"
MAPPING_DIR="${CONFIG_DIR}/mappings"

source joy_common.sh "flycast"

CONFIG_TMP_A="/tmp/jc/SDLflycastA.tmp"
CONFIG_TMP_D="/tmp/jc/SDLflycastD.tmp"
CONFIG_TMP_E="/tmp/jc/SDLflycastE.tmp"

BTN_H0=$(get_ee_setting flycast_btn_h0)
[[ -z "${BTN_H0}" ]] && BTN_H0=255

declare -A FLYCAST_D_INDEXES=(
  [h0.1]=$(( BTN_H0+1 ))
  [h0.4]=$(( BTN_H0+2 ))
  [h0.8]=$(( BTN_H0+3 ))
  [h0.2]=$(( BTN_H0+4 ))
)

declare -A FLYCAST_D_BUTTONS=(
  [x]="btn_y"
  [y]="btn_x"
  [a]="btn_b"
  [b]="btn_a"
  [leftshoulder]="btn_c"
  [rightshoulder]="btn_d"
  [lefttrigger]="btn_trigger_left"
  [righttrigger]="btn_trigger_right"
  [back]="btn_menu"
  [start]="btn_start"
  [guide]="btn_escape"
  [rightstick]="btn_fforward"
  [dpup]="btn_dpad1_up"
  [dpdown]="btn_dpad1_down"
  [dpleft]="btn_dpad1_left"
  [dpright]="btn_dpad1_right"
  [leftx]="axis_x"
  [lefty]="axis_y"
  [rightx]="axis_right_x"
  [righty]="axis_right_y"
)

BTN_SWAP_XY=$(get_ee_setting flycast_joy_swap_xy)
if [[ "${BTN_SWAP_XY}" == "1" ]]; then
  FLYCAST_D_BUTTONS[x]="btn_x"
  FLYCAST_D_BUTTONS[y]="btn_y"
fi

BTN_SWAP_AB=$(get_ee_setting flycast_joy_swap_ab)
if [[ "${BTN_SWAP_AB}" == "1" ]]; then
  FLYCAST_D_BUTTONS[a]="btn_a"
  FLYCAST_D_BUTTONS[b]="btn_b"
fi

declare -A STICK_DIRECTIONS=(
  [axis_x,neg]="btn_analog_left"  [axis_x,pos]="btn_analog_right"
  [axis_y,neg]="btn_analog_up"    [axis_y,pos]="btn_analog_down"
  [axis_right_x,neg]="axis2_left" [axis_right_x,pos]="axis2_right"
  [axis_right_y,neg]="axis2_up"   [axis_right_y,pos]="axis2_down"
)


# Cleans all the inputs for the gamepad with name ${GAMEPAD} and player ${1}
clean_pad() {
  #echo "Cleaning pad ${1} ${2}" #debug
  [[ -f "${CONFIG_TMP_A}" ]] && rm "${CONFIG_TMP_A}"
  [[ -f "${CONFIG_TMP_D}" ]] && rm "${CONFIG_TMP_D}"
  [[ -f "${CONFIG_TMP_E}" ]] && rm "${CONFIG_TMP_E}"
  sed -i "s/device${1}\.2.*/device${1}.2 = 10/g" "${EMU_FILE}"
  sed -i "s/device${1}\.1.*/device${1}.1 = 10/g" "${EMU_FILE}"
  sed -i "s/device${1} .*/device${1} = 10/g" "${EMU_FILE}"
  local i=$(( ${1} - 1 ))
  sed -i "s/maple_sdl_joystick_${i}.*/maple_sdl_joystick_${i} = -1/g" "${EMU_FILE}"
}

# Sets pad depending on parameters.
# ${1} = Player Number
# ${2} = js[0-7]
# ${3} = Device GUID
# ${4} = Device Name

set_pad() {
  echo "set_pad params: ${1} ${2} ${3} ${4}"
  local JOY_NAME="${4}"
  local ORDER=${7}
  local i=$(( ${1} - 1 ))

  # Vars to dinamically set triggers
  local L_TR_AXIS=""
  local R_TR_AXIS=""

  sed -i "s/device${1} .*/device${1} = 0/g" "${EMU_FILE}"


  local device1=1
  local RUMBLE=$(get_ee_setting ee_rumble_strength)
  [[ -z "${RUMBLE}" ]] && RUMBLE=0
  [[ "${RUMBLE}" -gt "0" ]] && device1=3

  sed -i "s/device${1}\.1.*/device${1}.1 = ${device1}/g" "${EMU_FILE}"
  sed -i "s/device${1}\.2.*/device${1}.2 = 1/g" "${EMU_FILE}"
  sed -i "s/maple_sdl_joystick_${i}.*/maple_sdl_joystick_${i} = ${ORDER}/g" "${EMU_FILE}"

  local CONFIG="${MAPPING_DIR}/SDL_${JOY_NAME}.cfg"
  [[ -f "${CONFIG}" ]] && rm "${CONFIG}"

  > "${CONFIG_TMP_A}"; > "${CONFIG_TMP_D}"; > "${CONFIG_TMP_E}"

  local GC_CONFIG="${5}"
  [[ -z ${GC_CONFIG} ]] && return
  local GC_MAP=$(echo ${GC_CONFIG} | cut -d',' -f3-)
  set -f
  local GC_ARRAY=(${GC_MAP//,/ })

  local B_COUNT_A=0
  local B_COUNT_D=0

  for REC in "${GC_ARRAY[@]}"; do
      local KEY=$(echo ${REC} | cut -d ":" -f 1)
      local TVAL=$(echo ${REC} | cut -d ":" -f 2)
      local TYPE=${TVAL:0:1}
      local NUM=${TVAL:1}
      local ACTION=${FLYCAST_D_BUTTONS[${KEY}]}

      [[ -z "${ACTION}" ]] && continue

      if [[ "${TYPE}" == "a" ]]; then
          # ANALOG SECTION
          if [[ "${KEY}" == "leftx" || "${KEY}" == "lefty" || "${KEY}" == "rightx" || "${KEY}" == "righty" ]]; then
              echo "bind$((B_COUNT_A++)) = ${NUM}-:${STICK_DIRECTIONS[${ACTION},neg]}" >> "${CONFIG_TMP_A}"
              echo "bind$((B_COUNT_A++)) = ${NUM}+:${STICK_DIRECTIONS[${ACTION},pos]}" >> "${CONFIG_TMP_A}"
          else
              # ITS ANALOG TRIGGER
              echo "bind$((B_COUNT_A++)) = ${NUM}+:${ACTION}" >> "${CONFIG_TMP_A}"
              # SAVE IDS FOR LATER
              [[ "${KEY}" == "lefttrigger" ]] && L_TR_AXIS="${NUM}"
              [[ "${KEY}" == "righttrigger" ]] && R_TR_AXIS="${NUM}"
          fi

      elif [[ "${TYPE}" == "b" || "${TYPE}" == "h" ]]; then
          # DIGITAL SECTION
          local FINAL_NUM=${NUM}
          [[ "${TYPE}" == "h" ]] && FINAL_NUM=${FLYCAST_D_INDEXES[${TVAL}]}

          echo "bind$((B_COUNT_D++)) = ${FINAL_NUM}:${ACTION}" >> "${CONFIG_TMP_D}"
      fi
  done

  echo "[analog]" > "${CONFIG}"
  cat "${CONFIG_TMP_A}" | sort >> "${CONFIG}"

  echo -e "\n[digital]" >> "${CONFIG}"
  cat "${CONFIG_TMP_D}" | sort >> "${CONFIG}"

  echo -e "\n[emulator]" >> "${CONFIG}"
  echo "mapping_name = ${JOY_NAME}" >> "${CONFIG}"
  echo "version = 4" >> "${CONFIG}"
  echo "rumble_power = ${RUMBLE}" >> "${CONFIG}"

  if [[ ! -z "${L_TR_AXIS}" && ! -z "${R_TR_AXIS}" ]]; then
      echo "triggers = ${L_TR_AXIS},${R_TR_AXIS}" >> "${CONFIG}"
  fi

  cat "${CONFIG_TMP_E}" | sort -u >> "${CONFIG}"

  rm "${CONFIG_TMP_A}" "${CONFIG_TMP_D}" "${CONFIG_TMP_E}"
}

init_config() {
  mkdir -p "/storage/.config/flycast/mappings"

  # Adjust the emulator config file to load sdl controller files.
  if [[ ! -f "${EMU_FILE}" ]]; then
    echo "[input]" >> "${EMU_FILE}"

    local SDL_JOYSTICK="maple_sdl_joystick_0 = 0\nmaple_sdl_joystick_1 = 1\nmaple_sdl_joystick_2 = 2\nmaple_sdl_joystick_3 = 3\n"
    echo -e "${SDL_JOYSTICK}" >> "${EMU_FILE}"

    for i in {1..4}; do
      echo -e "device${i} = 0\ndevice${i}.1 = 1\ndevice{$i}.2 = 1\n" >> "${EMU_FILE}"
    done

    return
  fi

  local RUMBLE=$(get_ee_setting ee_rumble_strength)
  [[ -z "${RUMBLE}" ]] && RUMBLE=0

  jc_set_record "${EMU_FILE}" "\[input\]" "VirtualGamepadVibration" "${RUMBLE}"
}


init_config

jc_get_players
