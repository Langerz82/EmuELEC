#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present Joshua L (https://github.com/Langerz82)

# Source predefined functions and variables
. /etc/profile

GCDB="${SDL_GAMECONTROLLERCONFIG_FILE}"

CMD="$1"

[[ ! "${CMD}" == "WIPE" ]] && EMULATOR="$1"

mkdir -p "/tmp/jc"

DEBUG_FILE="/tmp/jc/${EMULATOR}_joy_debug.cfg"
CACHE_FILE="/tmp/jc/${EMULATOR}_joy_cache.cfg"


jc_get_players() {
# You can set up to 8 player on ES
  declare -i PLAYER=1

# Dump gamepad information
  cat /proc/bus/input/devices \
    | grep -B 5 -A 3 -P "H\: Handlers=(?=.*?js[0-9])(?=.*?event[0-9]+).*$" \
    | grep -Ew -B 8 "B: KEY\=[0-9a-f ]+" > /tmp/input_devices

# Determine how many gamepads/players are connected
  JOYS=$(ls -ltr /dev/input/js* | awk '{print $8"\t"$9"\t"$10}' | sort \
    | awk '{print $3}' | cut -d'/' -f4)
  if [[ -f "/storage/.config/JOY_LEGACY_ORDER" ]]; then
    JOYS=$(ls -A1 /dev/input/js*| sort | sed "s|/dev/input/||g")
  fi

  declare -a PLAYER_CFGS=()

  for dev in $(echo $JOYS); do
    local JSI=$dev
    local DETAILS=$(cat /tmp/input_devices | grep -P "H\: Handlers(?=.*?[= ]${JSI} )" -B 5)

    local PROC_GUID=$(echo "${DETAILS}" | grep I: | sed "s|I:\ Bus=||" | sed "s|\ Vendor=||" | sed "s|\ Product=||" | sed "s|\ Version=||")
    local DEVICE_GUID=$(jc_generate_guid ${PROC_GUID})
    [[ -z "${DEVICE_GUID}" ]] && continue

    local GC_CONFIG=$(cat "$GCDB" | grep "$DEVICE_GUID" | grep "platform:Linux" | head -1)
    echo "GC_CONFIG=$GC_CONFIG"
    [[ -z $GC_CONFIG ]] && continue

    local JOY_NAME=$(echo "${DETAILS}" | grep -E "^N\: Name.*[\= ]?.*$" | cut -d "=" -f 2 | tr -d '"')
    [[ -z "$JOY_NAME" ]] && continue

    # Add the joy config to array if guid and joyname set.
    if [[ ! -z "${DEVICE_GUID}" && ! -z "$JOY_NAME" ]]; then
      local PLAYER_CFG="${JSI} ${DEVICE_GUID} \"${JOY_NAME}\""
      PLAYER_CFGS[$((PLAYER-1))]="${PLAYER_CFG}"
      ((PLAYER++))
    fi
  done

  rm /tmp/input_devices

  if [[ -z "${PLAYER_CFGS[@]}" ]]; then
    echo "NO GAME CONTROLLERS WERE DETECTED."
    return
  fi

  local cfgCount=${#PLAYER_CFGS[@]}
  MANUAL_CONFIG=$(cat "/tmp/controllerconfig.txt")
  echo "MANUAL_CONFIG=${MANUAL_CONFIG}"
  if [[ ! -z "${MANUAL_CONFIG}" && ! -f "/storage/.config/EE_CONTROLLER_OVERIDE_OFF" ]]; then
    declare -a GUID_ORDER=($MANUAL_CONFIG)
    declare -a GUIDS=()

    local index=0
    local row=0
    local i=0
    local pl=0
    for i in ${GUID_ORDER[@]}; do
      row=$(( index % 4 ))
      [[ $row == 0 ]] && pl=${i:2:1}
      [[ $row == 3 ]] && GUIDS[$pl]=${GUID_ORDER[$(( index+0 ))]}
      (( index++ ))
    done
    echo "GUID_ORDER=${GUIDS[@]}"
    local si=0
    for (( i=1; i<=$cfgCount; i++ )); do
      local tGUID=${GUIDS[i]}
      [[ "$tGUID" == "" ]] && continue
      for (( j=$si; j<$cfgCount; j++ )); do
        local cfgGUID=$(echo "${PLAYER_CFGS[$j]}" | cut -d' ' -f2)
        if [[ $tGUID == $cfgGUID ]]; then
          local tmp="${PLAYER_CFGS[$j]}"
          PLAYER_CFGS[$j]="${PLAYER_CFGS[$si]}"
          PLAYER_CFGS[$si]="$tmp"
          (( si++ ))
          break
        fi
      done
    done
  fi

  local PLAYER_CFG=
  mkdir -p /tmp/JOYPAD_NAMES
  rm /tmp/JOYPAD_NAMES/*.txt 2>/dev/null
  for p in {1..4}; do
    local CFG="${p} ${PLAYER_CFGS[$(( p-1 ))]}"
    if [[ $p -le $cfgCount ]]; then
      echo "PLAYER_CFG=${CFG}"
    fi
    eval clean_pad ${CFG}
    if [[ "${CFG}" != "${p} " ]]; then
      local JOYNAME=$(echo "${CFG}" | cut -d' ' -f4-)
      echo "$JOYNAME" > "/tmp/JOYPAD_NAMES/JOYPAD${p}.txt"
      eval set_pad ${CFG}
    fi
  done
}

jc_generate_guid() {
  local GUID_STRING="$1"

  local p1=${GUID_STRING::4}
  local p2=${GUID_STRING:4:4}
  local p3=${GUID_STRING:8:4}
  local p4=${GUID_STRING:12:4}

  local v=$(echo ${p1:6:2}${p1:4:2}${p1:2:2}${p1:0:2})0000
        v+=$(echo ${p2:6:2}${p2:4:2}${p2:2:2}${p2:0:2})0000
        v+=$(echo ${p3:6:2}${p3:4:2}${p3:2:2}${p3:0:2})0000
        v+=$(echo ${p4:6:2}${p4:4:2}${p4:2:2}${p4:0:2})0000

  echo "$v"
}

declare -A GC_CORES=(
#  [2048]=""
#  [81]=""
#  [atari800]=""
#  [bluemsx]=""
#  [cannonball]=""
#  [cap32]=""
#  [crocods]=""
#  [daphne]=""
#  [dinothawr]=""
#  [dosbox_svn]=""
  [duckstation]="DuckStation"
#  [easrpg]=""  
  [fbalpha2012]="FB Alpha 2012"
  [fbneo]="FinalBurn Neo"
#  [fceumm]=""
  [flycast]="Flycast"
#  [freeintv]=""
#  [fuse]=""
#  [gambatte]=""
#  [gearboy]=""
#  [gearsystem]=""
#  [genesis_plus_gx]=""
#  [genesis_plus_gx_wide]=""
#  [gme]=""
#  [gpsp]=""
#  [gw]=""
#  [handy]=""
#  [hatari]=""  
  [mame2003]="MAME 2003-Plus"
  [mame2010]="MAME 2010"
  [mame2016]="MAME 2016"
#  [mednafen_lynx]=""
#  [mednafen_ngp]=""
#  [mednafen_pce_fast]=""
#  [mednafen_pcfx]=""
#  [mednafen_supergrafx]=""
#  [mednafen_vb]=""
#  [mednafen_wswan]=""
#  [mesen-s]=""
#  [mgba]=""
#  [mrboom]=""
#  [mupen64plus]="Mupen64Plus"
  [mupen64plus]="Mupen64Plus GLES2"
#  [mupen64plus_next]="Mupen64Plus-Next"
  [mupen64plus_next]="Mupen64Plus-Next GLES2"
  [nekop2]="Neko Project II"
#  [neocd]=""
#  [nestopiaCV]=""
#  [nestopia]=""
  [np2kai]="Neko Project II kai"
#  [nxengine]=""
#  [o2em]=""
#  [opera]=""
  [parallel_n64]="ParaLLEl N64"
  [pcsx_rearmed]="PCSX-ReARMed"
#  [pcsx_rearmed_32b]=""
#  [picodrive]=""
#  [pokemini]=""
#  [ppsspp]=""
#  [prboom]=""
#  [prosystem]=""
#  [puae]=""
#  [px68k]=""
#  [quasi88]=""
#  [quicknes]=""
#  [reminiscence]=""
#  [sameboy]=""
#  [scummvm]=""
#  [snes9x2002]=""
#  [snes9x2005_plus]=""
#  [snes9x2010]=""
#  [snes9x]=""
#  [stella]=""
  [swanstation]="SwanStation"
#  [tgbdual]=""
#  [tyrquake]=""
#  [uae4arm]=""
#  [uzem]=""
#  [vba_next]=""
#  [vbam]=""
#  [vecx]=""
#  [vice_x128]=""
#  [vice_x64]=""
#  [vice_xplus4]=""
#  [vice_xvic]=""
#  [virtualjaguar]=""
#  [x1]=""
#  [xrick]=""
#  [yabasanshiro]=""
)

wipe_gamepad()
{
  EMULATOR="${1}"
  CORE="${GC_CORES[${2}]}"

  local LIBRETRO_REMAP="/storage/.config/retroarch/config/remappings/${CORE}/${CORE}.rmp"
  local ADVMAME_CONFIG="/storage/.advance/advmame.rc"
  local FB_CFG_DIR="/emuelec/configs/fbneo/config/"

  case ${EMULATOR} in
    "FBNEOSA")
      sed -i "/input \"p1.*/d" "${FB_CFG_DIR}p1defaults.ini"
      sed -i "/input \"p2.*/d" "${FB_CFG_DIR}p2defaults.ini"
      sed -i "/input \"p3.*/d" "${FB_CFG_DIR}p3defaults.ini"
      sed -i "/input \"p4.*/d" "${FB_CFG_DIR}p4defaults.ini"
      ;;
    "AdvanceMame")
      sed -i "/device_joystick.*/d" ${ADVMAME_CONFIG}
      sed -i "/input_map\[.*/d" ${ADVMAME_CONFIG}      
      ;;
    "libretro")
      sed -i "/input_player[0-9]*_.*_btn.*/d" "${LIBRETRO_REMAP}"
      sed -i "/input_player[0-9]*_.*_axis.*/d" "${LIBRETRO_REMAP}"      
      ;;
  esac
}

if [[ "${CMD}" == "WIPE" ]]; then 
  EMULATOR="${2}"
  CORE="${3}"
  wipe_gamepad "${EMULATOR}" "${CORE}"
fi

