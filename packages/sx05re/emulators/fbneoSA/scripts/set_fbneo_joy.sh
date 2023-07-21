#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present Joshua L (https://github.com/Langerz82)

# Source predefined functions and variables
. /etc/profile

source joy_common.sh "fbneosa"

EE_CFG="/emuelec/configs/emuelec.conf"
FB_CFG_DIR="/emuelec/configs/fbneo/config/"

PLATFORM=$1
EMULATOR="FBNEOSA"
CORE="FbneoSA"
ROMNAME="${2}"

CONFIG_DIR="/tmp/joypads_fbn/"
mkdir -p ""${CONFIG_DIR}""

BTN_CFG="0 1 2 3 4 5 6 7"

declare -A FBN_VALUES=(
  ["b0"]="switch 0x4080"
  ["b1"]="switch 0x4081"
  ["b2"]="switch 0x4082"
  ["b3"]="switch 0x4083"
  ["b4"]="switch 0x4084"
  ["b5"]="switch 0x4085"
  ["b6"]="switch 0x4086"
  ["b7"]="switch 0x4087"
  ["b8"]="switch 0x4088"
  ["b9"]="switch 0x4089"
  ["b10"]="switch 0x4090"
  ["b11"]="switch 0x4091"
  ["b12"]="switch 0x4092"
  ["b13"]="switch 0x4093"
  ["b14"]="switch 0x4094"
  ["b15"]="switch 0x4095"
  ["b16"]="switch 0x4096"
  ["b17"]="switch 0x4097"
  ["h0.1"]="switch 0x4012"
  ["h0.4"]="switch 0x4013"
  ["h0.8"]="switch 0x4010"
  ["h0.2"]="switch 0x4011"
  ["a0,1"]="switch 0x4000"
  ["a0,2"]="switch 0x4001"
  ["a1,1"]="switch 0x4002"
  ["a1,2"]="switch 0x4003"
  ["a2"]="switch 0x4004"
  #["a3,1"]="switch 0x4005"
  #["a3,2"]="switch 0x4006"
  #["a4,1"]="switch 0x4007"
  #["a4,2"]="switch 0x4008"
  ["a5"]="switch 0x4009"
)

declare -A FBN_BUTTONS=(
  [dpleft]="left"
  [dpright]="right"
  [dpup]="up"
  [dpdown]="down"
  [a]="fire 1"
  [b]="fire 2"
  [x]="fire 3"
  [y]="fire 4"

  [lefttrigger]="fire 7"
  [righttrigger]="fire 8"
  [back]="coin"
  [start]="start"
  [leftshoulder]="fire 5"
  [rightshoulder]="fire 6"
  [leftthumb]="fire 9"
  [rightthumb]="fire 10"

  [leftx,1]="left"
  [leftx,2]="right"
  [lefty,1]="up"
  [lefty,2]="down"
  #[rightx,1]=""
  #[rightx,2]=""
  #[righty,1]=""
  #[righty,2]=""
)

declare FBN_ORDER=(
  "a"
  "b"
  "x"
  "y"
  "leftshoulder"
  "rightshoulder"
  "lefttrigger"
  "righttrigger"
)

declare -A GC_NAMES=()

get_button_cfg() {
	local BTN_INDEX=$(get_ee_setting "joy_btn_cfg" "${PLATFORM}" "${ROMNAME}")
  [[ -z $BTN_INDEX ]] && BTN_INDEX=$(get_ee_setting "${PLATFORM}.joy_btn_cfg")

  if [[ ! -z $BTN_INDEX ]] && [[ $BTN_INDEX -gt 0 ]]; then
		local BTN_SETTING="${EMULATOR}.joy_btn_order$BTN_INDEX"
    local BTN_CFG_TMP="$(get_ee_setting $BTN_SETTING)"
		[[ ! -z $BTN_CFG_TMP ]] && BTN_CFG="${BTN_CFG_TMP}"
	fi
	echo "$BTN_CFG"
}


		
clean_pad() {
  echo "clean_pad()"
	sed -i "/input \"p${1}.*/d" "${FB_CFG_DIR}p${1}defaults.ini"
}


# Sets pad depending on parameters $GAMEPAD = name $1 = player
set_pad(){
  local P_INDEX=$(( $1 - 1 ))
  local DEVICE_GUID=$3
  local JOY_NAME="$4"

  local GC_CONFIG=$(cat "$GCDB" | grep "$DEVICE_GUID" | grep "platform:Linux" | head -1)
  echo "GC_CONFIG=$GC_CONFIG"
  [[ -z $GC_CONFIG ]] && return

  [[ -z "$JOY_NAME" ]] && JOY_NAME=$(echo $GC_CONFIG | cut -d',' -f2)
  [[ -z "$JOY_NAME" ]] && return

  CONFIG="${CONFIG_DIR}/player${1}.cfg"
  CONFIG_M="${CONFIG_DIR}/player_menu.cfg"

  rm "${CONFIG}"

  local GC_MAP=$(echo $GC_CONFIG | cut -d',' -f3-)

  local i=1
  set -f
  local GC_ARRAY=(${GC_MAP//,/ })
  declare -A GC_ASSOC=()
  for index in "${!GC_ARRAY[@]}"; do
    local REC=${GC_ARRAY[$index]}
    local GC_INDEX=$(echo $REC | cut -d ":" -f 1)
    [[ $GC_INDEX == "" || $GC_INDEX == "platform" ]] && continue

    local TVAL=$(echo $REC | cut -d ":" -f 2)
    GC_ASSOC["$GC_INDEX"]=$TVAL

    [[ " ${FBN_ORDER[*]} " == *" ${GC_INDEX} "* ]] && continue
    local BUTTON_VAL=${TVAL:1}
    local BTN_TYPE=${TVAL:0:1}

    local FIELD="${FBN_BUTTONS[${GC_INDEX}]}"
    local VAL="${FBN_VALUES[${TVAL}]}"

    # Create ordinary buttons and analog dirs.
    case $GC_INDEX in
      back|start)
        if [[ "$BTN_TYPE" == "b" ]]; then
          echo "input \"p${1} ${FIELD}\" ${VAL}" >> "${CONFIG}"
        fi
        ;;      
      dpup|dpdown|dpleft|dpright)
        if [[ "$BTN_TYPE" == "b" ]]; then
          echo "macro \"p${1} ${FIELD}\" ${VAL}" >> "${CONFIG}"
        elif [[ "$BTN_TYPE" == "h" ]]; then
          echo "macro \"p${1} ${FIELD}\" ${VAL}" >> "${CONFIG}"
        fi
        ;;
      leftx|lefty)
        if [[ "$BTN_TYPE" == "a" ]]; then
          FIELD="${FBN_BUTTONS[${GC_INDEX},1]}"
          VAL="${FBN_VALUES[${TVAL},1]}"
          echo "input \"p${1} ${FIELD}\" ${VAL}" >> "${CONFIG}"

          FIELD="${FBN_BUTTONS[${GC_INDEX},2]}"
          VAL="${FBN_VALUES[${TVAL},2]}"            
          echo "input \"p${1} ${FIELD}\" ${VAL}" >> "${CONFIG}"
        fi
    esac
  done

  declare -i i=0
  for bi in ${BTN_CFG}; do
    local button="${FBN_ORDER[$i]}"
    local FIELD="${FBN_BUTTONS[${button}]}"
    [[ -z "$button" ]] && continue
    local vi="${FBN_ORDER[$bi]}"
    button="${GC_ASSOC[${vi}]}"
    local BTN_TYPE="${button:0:1}"
    local VAL="${FBN_VALUES[${button}]}"
    
    if [[ "$BTN_TYPE" == "a" ]]; then
      echo "input \"p${1} ${FIELD}\" ${VAL}" >> "${CONFIG}"
    elif [[ "$BTN_TYPE" == "b" ]]; then
      echo "input \"p${1} ${FIELD}\" ${VAL}" >> "${CONFIG}"
    elif [[ "$BTN_TYPE" == "h" ]]; then
      echo "input \"p${1} ${FIELD}\" ${VAL}" >> "${CONFIG}"
    fi
    (( i++ ))
  done

  PC_FILE="/emuelec/configs/fbneo/config/p${1}defaults.ini"
  rm ${PC_FILE}
  echo "version 0x100003" > "${PC_FILE}"

  cat "${CONFIG}" >> "${PC_FILE}"

}

BTN_CFG=$(get_button_cfg)

echo "BTN_CFG=$BTN_CFG"

jc_get_players

