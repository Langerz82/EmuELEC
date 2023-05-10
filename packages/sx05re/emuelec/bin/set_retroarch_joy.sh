#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present Joshua L (https://github.com/Langerz82)

# Source predefined functions and variables
. /etc/profile


CONFIG="/tmp/joypads_ra"
mkdir -p ""${CONFIG}""
EE_CFG="/emuelec/configs/emuelec.conf"

source joy_common.sh "retroarch"

PLATFORM=$1
EMULATOR=$2
ROMNAME=$3

BTN_CFG="0 1 2 3 4 5 6 7"

declare -A RA_VALUES=(
  ["b0"]="0"
  ["b1"]="1"
  ["b2"]="2"
  ["b3"]="3"
  ["b4"]="4"
  ["b5"]="5"
  ["b6"]="6"
  ["b7"]="7"
  ["b8"]="8"
  ["b9"]="9"
  ["b10"]="10"
  ["b11"]="11"
  ["b12"]="12"
  ["b13"]="13"
  ["b14"]="14"
  ["b15"]="15"
  ["b16"]="16"
  ["b17"]="17"
  ["h0.1"]="h0up"
  ["h0.4"]="h0down"
  ["h0.8"]="h0left"
  ["h0.2"]="h0right"
  ["a0,1"]="-0"
  ["a0,2"]="+0"
  ["a1,1"]="-1"
  ["a1,2"]="+1"
  ["a2"]="+2"
  ["a2,1"]="-2"
  ["a2,2"]="+2"
  ["a3,1"]="-3"
  ["a3,2"]="+3"
  ["a4,1"]="-4"
  ["a4,2"]="+4"
  ["a5"]="+5"
  ["a5,1"]="-5"
  ["a5,2"]="+5"
)

declare -A RA_BUTTONS=(
  [dpleft]="input_left_btn"
  [dpleft,m]="input_state_slot_decrease_btn"
  [dpright]="input_right_btn"
  [dpright,m]="input_state_slot_increase_btn"
  [dpup]="input_up_btn"
  [dpup,m]="input_volume_up_btn"
  [dpdown]="input_down_btn"
  [dpdown,m]="input_volume_down_btn"
  [x]="input_x_btn"
  [x,m]="input_menu_toggle_btn"
  [y]="input_y_btn"
  [a]="input_a_btn"
  [b]="input_b_btn"
  [b,m]="input_reset_btn"
  [lefttrigger]="input_l2_axis"
  [lefttrigger,m]="input_rewind_axis"
  [righttrigger]="input_r2_axis"
  [righttrigger,m]="input_toggle_fast_forward_axis"
  [back]="input_select_btn"
  [back,m]="input_enable_hotkey_btn"
  [start]="input_start_btn"
  [start,m]="input_exit_emulator_btn"
  [leftshoulder]="input_l_btn"
  [leftshoulder,m]="input_load_state_btn"
  [rightshoulder]="input_r_btn"
  [leftthumb]="input_l3_btn"
  [rightthumb]="input_r3_btn"
  [rightthumb,m]="input_fps_toggle_btn"
  [leftx,1]="input_l_x_minus_axis"
  [leftx,2]="input_l_x_plus_axis"
  [lefty,1]="input_l_y_minus_axis"
  [lefty,2]="input_l_y_plus_axis"
  [rightx,1]="input_r_x_minus_axis"
  [rightx,2]="input_r_x_plus_axis"
  [righty,1]="input_r_y_minus_axis"
  [righty,2]="input_r_y_plus_axis"
)

declare GC_ORDER=(
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

  local GAMEPAD="$( cat "/tmp/JOYPAD_NAMES/JOYPAD${1}.txt" | cut -d'"' -f 2 )"

  CONFIG="${CONFIG}/${GAMEPAD}.cfg"

  rm "${CONFIG}"

  OLD_CONFIG="/tmp/joypads/${GAMEPAD}.cfg"
  VENDOR=0
  PRODUCT=0
  if [[ -f "${OLD_CONFIG}" ]]; then
    VENDOR=$( cat "${OLD_CONFIG}" | grep "input_vendor_id" | cut -d'"' -f 2 )
    PRODUCT=$( cat "${OLD_CONFIG}" | grep "input_product_id" | cut -d'"' -f 2 )
  fi
  echo "input_device = \"${GAMEPAD}\"" >> "${CONFIG}"
  echo "input_driver = \"udev\"" >> "${CONFIG}"
  echo "input_vendor_id = \"${VENDOR}\"" >> "${CONFIG}"
  echo "input_product_id = \"${PRODUCT}\"" >> "${CONFIG}"

  local GC_MAP=$(echo $GC_CONFIG | cut -d',' -f3-)

  local i=1
  set -f
  local GC_ARRAY=(${GC_MAP//,/ })
  declare -A GC_ASSOC=()
  for index in "${!GC_ARRAY[@]}"
  do
      local REC=${GC_ARRAY[$index]}
      local GC_INDEX=$(echo $REC | cut -d ":" -f 1)
      [[ $GC_INDEX == "" || $GC_INDEX == "platform" ]] && continue

      local TVAL=$(echo $REC | cut -d ":" -f 2)
      GC_ASSOC["$GC_INDEX"]=$TVAL

      [[ " ${GC_ORDER[*]} " == *" ${GC_INDEX} "* ]] && continue
      local BUTTON_VAL=${TVAL:1}
      local BTN_TYPE=${TVAL:0:1}

      local FIELD="${RA_BUTTONS[${GC_INDEX}]}"
      local VAL="${RA_VALUES[${TVAL}]}"

      # Create ordinary buttons and analog dirs.
      case $GC_INDEX in
        dpup|dpdown|dpleft|dpright|back|start)
          if [[ "$BTN_TYPE" == "b" ]]; then
            echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
          elif [[ "$BTN_TYPE" == "h" ]]; then
            echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
          fi

          FIELD="${RA_BUTTONS[${GC_INDEX},m]}"
          [[ ! -z ${FIELD} ]] && echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
          ;;
        leftx|lefty|rightx|righty)
          if [[ "$BTN_TYPE" == "a" ]]; then
            FIELD="${RA_BUTTONS[${GC_INDEX},1]}"
            VAL="${RA_VALUES[${TVAL},1]}"
            echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"

            FIELD="${RA_BUTTONS[${GC_INDEX},2]}"
            VAL="${RA_VALUES[${TVAL},2]}"            
            echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
            
            FIELD="${RA_BUTTONS[${GC_INDEX},m]}"
            [[ ! -z ${FIELD} ]] && echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
          fi
      esac
  done

  declare -i i=0
  for bi in ${BTN_CFG}; do
    local button="${GC_ORDER[$i]}"
    local FIELD="${RA_BUTTONS[${button}]}"
    local FIELD2="${RA_BUTTONS[${button},m]}"
    [[ -z "$button" ]] && continue

    local vi="${GC_ORDER[$bi]}"
    button="${GC_ASSOC[${vi}]}"
    local BTN_TYPE="${button:0:1}"
    local VAL="${RA_VALUES[${button}]}"
    
    if [[ "$BTN_TYPE" == "a" ]]; then
      echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
      [[ ! -z ${FIELD2} ]] && echo "${FIELD2} = \"${VAL}\"" >> "${CONFIG}"
    elif [[ "$BTN_TYPE" == "b" ]]; then
      echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
      [[ ! -z ${FIELD2} ]] && echo "${FIELD2} = \"${VAL}\"" >> "${CONFIG}"
    elif [[ "$BTN_TYPE" == "h" ]]; then
      echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
      [[ ! -z ${FIELD2} ]] && echo "${FIELD2} = \"${VAL}\"" >> "${CONFIG}"
    fi
    (( i++ ))
  done

}

BTN_CFG=$(get_button_cfg)
echo "BTN_CFG=$BTN_CFG"

sed -i "s|joypad_autoconfig_dir =.*|joypad_autoconfig_dir = /tmp/joypads_ra|" "/storage/.config/retroarch/retroarch.cfg"

jc_get_players
