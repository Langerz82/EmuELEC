#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present Joshua L (https://github.com/Langerz82)

# Source predefined functions and variables
. /etc/profile

source joy_common.sh "retroarch"

EE_CFG="/emuelec/configs/emuelec.conf"

PLATFORM="$1"
EMULATOR="$2"
CORE="$3"
ROMNAME="$4"

CONFIG_DIR="/tmp/joypads_ra/${CORE}/"
mkdir -p ""${CONFIG_DIR}""

[[ ! -z "${GC_CORES[${CORE}]}" ]] && CORE_REMAP="${GC_CORES[${CORE}]}"
mkdir -p "/storage/.config/retroarch/config/remappings/${CORE_REMAP}"
REMAP_FILE="/storage/.config/retroarch/config/remappings/${CORE_REMAP}/${CORE_REMAP}.rmp"

BTN_CFG_DEF="0 1 2 3 4 5 6 7"

declare -A RA_VALUES=(
  ["b0"]="0"
  ["b1"]="8"
  ["b2"]="1"
  ["b3"]="9"
  ["b4"]="10"
  ["b5"]="11"
  ["b6"]="2"
  ["b7"]="3"
  #["b8"]="1"
  ["b9"]="2"
  ["b10"]="3"
  ["b11"]="12"
  ["b12"]="13"
  ["b13"]="4"
  ["b14"]="5"
  ["b15"]="6"
  ["b16"]="7"
  ["h0.1"]="4"
  ["h0.4"]="5"
  ["h0.8"]="6"
  ["h0.2"]="7"
  ["a0,1"]="-0"
  ["a0,2"]="+0"
  ["a1,1"]="-1"
  ["a1,2"]="+1"
  ["a2"]="12"
  ["a2,1"]="-2"
  ["a2,2"]="+2"
  ["a3,1"]="-3"
  ["a3,2"]="+3"
  ["a4,1"]="-4"
  ["a4,2"]="+4"
  ["a5"]="13"
  ["a5,1"]="-5"
  ["a5,2"]="+5"
)

declare -A RA_BUTTONS=(
  [dpleft]="input_btn_left"
  [dpright]="input_btn_right"
  [dpup]="input_btn_up"
  [dpdown]="input_btn_down"
  [a]="input_btn_a"
  [b]="input_btn_b"
  [x]="input_btn_x"
  [y]="input_btn_y"
  
  [lefttrigger]="input_btn_l2"
  [righttrigger]="input_btn_r2"
  [back]="input_btn_select"
  [start]="input_btn_start"
  [leftshoulder]="input_btn_l"
  [rightshoulder]="input_btn_r"
  [leftthumb]="input_btn_l3"
  [rightthumb]="input_btn_r3"

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

declare -A RA_MENU=(
  [dpleft]="input_state_slot_decrease_btn"
  [dpright]="input_state_slot_increase_btn"
  [dpup]="input_volume_up_btn"
  [dpdown]="input_volume_down_btn"
  [x]="input_menu_toggle_btn"
  [b]="input_reset_btn"
  [lefttrigger]="input_rewind_axis"
  [righttrigger]="input_toggle_fast_forward_axis"
  [back]="input_enable_hotkey_btn"
  [start]="input_exit_emulator_btn"
  [leftshoulder]="input_load_state_btn"
  [rightshoulder]="input_save_state_btn"
  [rightthumb]="input_fps_toggle_btn"
)

declare -A GC_NAMES=()



get_button_cfg() {
	local L_BTN_CFG="$BTN_CFG_DEF"
	local BTN_INDEX=$(get_ee_setting "joy_btn_cfg" "${PLATFORM}" "${ROMNAME}")
  [[ -z $BTN_INDEX ]] && BTN_INDEX=$(get_ee_setting "${PLATFORM}.joy_btn_cfg")
  if [[ ! -z $BTN_INDEX ]] && [[ $BTN_INDEX -gt 0 ]]; then
		local BTN_SETTING="${EMULATOR}.joy_btn_order$BTN_INDEX"
    local BTN_CFG_TMP="$(get_ee_setting $BTN_SETTING)"
		[[ ! -z $BTN_CFG_TMP ]] && L_BTN_CFG="${BTN_CFG_TMP}"
	fi
	echo "$L_BTN_CFG"
}


clean_pad() {
  echo "clean_pad()"
#	[[ ! -z "${GC_CORES[${CORE}]}" ]] && CORE="${GC_CORES[${CORE}]}"
#  mkdir -p "/storage/.config/retroarch/config/remappings/${CORE}"
#  local REMAP_FILE="/storage/.config/retroarch/config/remappings/${CORE}/${CORE}.rmp"
  if [[ -f "${REMAP_FILE}" ]]; then
    sed -i "/input_player${1}_btn.*/d" "${REMAP_FILE}"
#    sed -i "/input_player${1}.*axis.*/d" "${REMAP_FILE}"
  fi	
}


# Sets pad depending on parameters $GAMEPAD = name $1 = player
set_pad(){
	if [[ "$G_BTN_CFG" == "$BTN_CFG_DEF" ]]; then
		return
	fi

  local P_INDEX=$(( $1 - 1 ))
  local DEVICE_GUID=$3
  local JOY_NAME="$4"

	CONFIG="${CONFIG_DIR}/player${1}.cfg"
#  CONFIG_M="${CONFIG_DIR}/player_menu.cfg"	
	[[ -f "${CONFIG}" ]] && rm "${CONFIG}"
	touch "${CONFIG}"
	#echo "input_joypad_index = \"${1}\"" > "${CONFIG}"

  local GC_CONFIG=$(cat "$GCDB" | grep "$DEVICE_GUID" | grep "platform:Linux" | head -1)
  echo "GC_CONFIG=$GC_CONFIG"
  [[ -z $GC_CONFIG ]] && return

  [[ -z "$JOY_NAME" ]] && JOY_NAME=$(echo $GC_CONFIG | cut -d',' -f2)
  [[ -z "$JOY_NAME" ]] && return

  #local GAMEPAD="$( cat "/tmp/JOYPAD_NAMES/JOYPAD${1}.txt" | cut -d'"' -f 2 )"

  # rm "${CONFIG_M}"

  #OLD_CONFIG="/tmp/joypads/${GAMEPAD}.cfg"
  #VENDOR=0
  #PRODUCT=0
  #if [[ -f "${OLD_CONFIG}" ]]; then
  #  VENDOR=$( cat "${OLD_CONFIG}" | grep "input_vendor_id" | cut -d'"' -f 2 )
  #  PRODUCT=$( cat "${OLD_CONFIG}" | grep "input_product_id" | cut -d'"' -f 2 )
  #fi
  
  #echo "input_device = \"${GAMEPAD}\"" >> "${CONFIG}"
  #echo "input_driver = \"udev\"" >> "${CONFIG}"
  #echo "input_vendor_id = \"${VENDOR}\"" >> "${CONFIG}"
  #echo "input_product_id = \"${PRODUCT}\"" >> "${CONFIG}"

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

#    [[ " ${GC_ORDER[*]} " == *" ${GC_INDEX} "* ]] && continue
#    local BUTTON_VAL=${TVAL:1}
#    local BTN_TYPE=${TVAL:0:1}

#    local FIELD="${RA_BUTTONS[${GC_INDEX}]}"
#    local VAL="${RA_VALUES[${TVAL}]}"

    # Create ordinary buttons and analog dirs.
#    case $GC_INDEX in
#      dpup|dpdown|dpleft|dpright|back|start)
#        if [[ "$BTN_TYPE" == "b" ]]; then
#          echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
#        elif [[ "$BTN_TYPE" == "h" ]]; then
#          echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
#        fi
#
#        FIELD="${RA_MENU[${GC_INDEX}]}"
#        [[ ! -z ${FIELD} ]] && echo "${FIELD} = \"${VAL}\"" >> "${CONFIG_M}"
#        ;;
#      leftx|lefty|rightx|righty)
#        if [[ "$BTN_TYPE" == "a" ]]; then
#          FIELD="${RA_BUTTONS[${GC_INDEX},1]}"
#          VAL="${RA_VALUES[${TVAL},1]}"
#          echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
#
#          FIELD="${RA_BUTTONS[${GC_INDEX},2]}"
#          VAL="${RA_VALUES[${TVAL},2]}"            
#          echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
#          
#          FIELD="${RA_MENU[${GC_INDEX}]}"
#          [[ ! -z ${FIELD} ]] && echo "${FIELD} = \"${VAL}\"" >> "${CONFIG_M}"
#        fi
#    esac
  done

  declare -i i=0
  for bi in ${G_BTN_CFG}; do
    local button="${GC_ORDER[$i]}"
    local FIELD="${RA_BUTTONS[${button}]}"
    local FIELD2="${RA_MENU[${button}]}"
    [[ -z "$button" ]] && continue

    local vi="${GC_ORDER[$bi]}"
    button="${GC_ASSOC[${vi}]}"
    local BTN_TYPE="${button:0:1}"
    local VAL="${RA_VALUES[${button}]}"
    
    if [[ "$BTN_TYPE" == "a" ]]; then
      echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
      #[[ ! -z ${FIELD2} ]] && echo "${FIELD2} = \"${VAL}\"" >> "${CONFIG_M}"
    elif [[ "$BTN_TYPE" == "b" ]]; then
      echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
      #[[ ! -z ${FIELD2} ]] && echo "${FIELD2} = \"${VAL}\"" >> "${CONFIG_M}"
    elif [[ "$BTN_TYPE" == "h" ]]; then
      echo "${FIELD} = \"${VAL}\"" >> "${CONFIG}"
      #[[ ! -z ${FIELD2} ]] && echo "${FIELD2} = \"${VAL}\"" >> "${CONFIG_M}"
    fi
    (( i++ ))
  done

	sed -i "s|input_*|input_player${1}_|" "${CONFIG}"

	local STR="input_libretro_device_p${1} = \"1\""
	grep -qx "${STR}" "${REMAP_FILE}" || echo "${STR}" >> "${REMAP_FILE}"
	STR="input_remap_port_p${1} = \"${P_INDEX}\""
	grep -qx "${STR}" "${REMAP_FILE}" || echo "${STR}" >> "${REMAP_FILE}"

  cat "${CONFIG}" | grep _btn_ >> "${REMAP_FILE}"
	rm "${CONFIG}"
	
#   if [[ "${1}" == "1" ]]; then
#    for menu_field in ${RA_MENU[*]}; do
#      sed -i "/${menu_field}.*/d" "${REMAP_FILE}"
#    done
#    cat "${CONFIG_M}" >> "${REMAP_FILE}"
#  fi

}

G_BTN_CFG=$(get_button_cfg)
echo "BTN_CFG=$G_BTN_CFG"


AUTOGP=$(get_ee_setting retroarch_auto_gamepad)
[[ "${AUTOGP}" == "1" ]] && jc_get_players

