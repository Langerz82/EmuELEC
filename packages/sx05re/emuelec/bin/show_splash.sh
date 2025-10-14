#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present SumavisionQ5 (https://github.com/SumavisionQ5)
# Modifications by Shanti Gilbert (https://github.com/shantigilbert)
# 2025-present Mod by DiegroSan
# 2025-present Mod by WorstcaseSecenario (https://github.com/worstcase-scenario)
# 2025-present Mod by Langerz82 (https://github.com/Langerz82)

# 12/07/2019 use mpv for all splash 
# 19/01/2020 use ffplay for all splash 
# 06/02/2020 move splash to roms folder and add global splash support
# 22/09/2025 various updates.

. /etc/profile

ACTION_TYPE="${1}"
PLATFORM="${2}"
ROMNAME="${3}"
BASEROMNAME=${ROMNAME##*/}
BASEROMNAME_NOEXT=${BASEROMNAME%.*}

GAMELOADINGSPLASH="/storage/.config/splash/loading-game.png"
BLANKSPLASH="/storage/.config/splash/blank.png"
DEFAULTSPLASH="/storage/.config/splash/splash-1080.png"
VIDEOSPLASH="/usr/config/splash/emuelec_intro_1080p.mp4"
RANDOMVIDEO="/storage/roms/splash/introvideos"

[ -f "/storage/roms/splash/intro.mp4" ] && VIDEOSPLASH="/storage/roms/splash/intro.mp4"

PLATFORM=${PLATFORM,,}
PLAYER_VID="ffplay"
PLAYER_IMG="mpv"

have_mpv=0

case ${PLATFORM} in
  arcade|fba|fbn|neogeo|mame|cps*) PLATFORM="arcade" ;;
  retropie|setup) exit 0 ;;
esac

MODE="$(get_resolution)"
SPLASHDIR="/storage/roms/splash"

IMAGE_EXT=(png jpg jpeg bmp gif)
VIDEO_EXT=(mp4 mkv webm avi mov mpg mpeg)

COMBINED_EXT=($( echo ${VIDEO_EXT[@]} ${IMAGE_EXT[@]} ))
FIND_COMBINED_EXT=$( echo ${COMBINED_EXT[@]} | sed 's/ /\\|/g')

mkdir -p /tmp/splash

function get_file_ext() {
	local MEDIA_FILES=()
	if [[ -d "${1}" ]]; then
		MEDIA_FILES=("$(find ${1} -maxdepth 1 -type f -name "${2}.*" -regex ".*\.\(${FIND_COMBINED_EXT}\)$")")
	fi
	if [[ ! -z "${MEDIA_FILES[@]}" ]]; then
		for CEXT in "${COMBINED_EXT[@]}"; do
			local FILE=$(echo "${MEDIA_FILES[@]}" | grep -e "^.*\.${CEXT}$" )
			local FILE_EXT="${FILE##*.}"
			if [[ "${CEXT}" == "${FILE_EXT}" ]]; then
			 echo "${FILE}" && return
			fi
		done
	fi
	echo ""
}

if [ "${ACTION_TYPE}" = "intro" ] || [ "${ACTION_TYPE}" = "exit" ]; then
 SPLASH="${DEFAULTSPLASH}"
 [[ "${MODE}" == *"x"* ]] && SPLASH="/storage/.config/splash/splash-std.png"

 if [ "${ACTION_TYPE}" = "exit" ]; then
   EE_SPLASH_EXIT="$(get_ee_setting ee_splashexit)"
   [[ -z "${EE_SPLASH_EXIT}" ]] && EE_SPLASH_EXIT=0

   CUSTOM_EXIT="$(get_ee_setting ee_customexitsplash)"

   if [ "${EE_SPLASH_EXIT}" = "1" ] && [ -n "${CUSTOM_EXIT}" ] && [ -f "${CUSTOM_EXIT}" ]; then
      SPLASH="${CUSTOM_EXIT}"
   fi
   [[ ! -f "${SPLASH}" ]] && SPLASH="${DEFAULTSPLASH}"
 fi

elif [ "${ACTION_TYPE}" = "blank" ]; then
  SPLASH="${BLANKSPLASH}"

elif [ "${ACTION_TYPE}" = "gameloading" ]; then
 [[ "${MODE}" == *"x"* ]] && GAMELOADINGSPLASH="/storage/.config/splash/loading-game-std.png"

 EE_SPLASH_LOADING="$(get_ee_setting ee_splashloading)"
 [[ -z "${EE_SPLASH_LOADING}" ]] && EE_SPLASH_LOADING=0

 CUSTOM_SPLASH="$(get_ee_setting ee_customsplash)"

 SPLASH=$(get_file_ext "${SPLASHDIR}/${PLATFORM}" "${BASEROMNAME_NOEXT}")
 [[ -z "${SPLASH}" ]] && SPLASH=$(get_file_ext "${SPLASHDIR}/${PLATFORM}" "${PLATFORM}")
 [[ -z "${SPLASH}" ]] && SPLASH=$(get_file_ext "${SPLASHDIR}/${PLATFORM}" "launching")

 if [ "${EE_SPLASH_LOADING}" = "0" ]; then
   [[ -z "${SPLASH}" ]] && SPLASH=${GAMELOADINGSPLASH}
 elif [ "${EE_SPLASH_LOADING}" = "1" ] && [ -n "${CUSTOM_SPLASH}" ] && [ -f "${CUSTOM_SPLASH}" ]; then
   [[ -z "${SPLASH}" ]] && SPLASH="${CUSTOM_SPLASH}"
 elif [ "${EE_SPLASH_LOADING}" = "2" ]; then
	 [[ -z "${SPLASH}" ]] && SPLASH="$(find "${SPLASHDIR}/random" -maxdepth 1 -type f -regex ".*\.\(${FIND_COMBINED_EXT}\)$" 2>/dev/null | sort -R | head -n 1)"
 else
   SPLASH="${GAMELOADINGSPLASH}"
 fi
 [[ ! -f "${SPLASH}" ]] && SPLASH="${GAMELOADINGSPLASH}"
fi

# OGA/GameForce -> mpv
SS_DEVICE=0
if [[ "${EE_DEVICE}" == "OdroidGoAdvance" ]] || [[ "${EE_DEVICE}" == "GameForce" ]]; then
  SS_DEVICE=1
  clear > /dev/console
  echo "Loading ..." > /dev/console
  PLAYER_VID="mpv"
  PLAYER_IMG="mpv"
  have_mpv=1
fi

declare -a RES=( ${MODE} )
SCALE="${RES[0]}:${RES[1]}"
FILTER_FILL="scale=${SCALE}:force_original_aspect_ratio=increase,crop=${RES[0]}:${RES[1]},setsar=1"
MPV_VF="${FILTER_FILL}"

[[ "${ACTION_TYPE}" != "intro" ]] && VIDEO=0 || VIDEO="$(get_ee_setting ee_bootvideo.enabled)"

is_video() { case "${1,,}" in *.mp4|*.mkv|*.webm|*.avi|*.mov|*.mpg|*.mpeg) return 0;; *) return 1;; esac; }
is_image() { case "${1,,}" in *.png|*.jpg|*.jpeg|*.bmp|*.gif) return 0;; *) return 1;; esac; }

if [[ -f "/storage/.config/emuelec/configs/novideo" ]] && [[ ${VIDEO} != "1" ]]; then
 if [ "${ACTION_TYPE}" != "intro" ]; then
   LOADING_DURATION="$(get_ee_setting ee_splash_loading_duration)"
   DURATION="${LOADING_DURATION}"
   FALLBACK_SPLASH="${GAMELOADINGSPLASH}"

   if [ "${ACTION_TYPE}" = "exit" ]; then
     EXIT_DURATION="$(get_ee_setting ee_splash_exit_duration)"
     DURATION="${EXIT_DURATION}"
     FALLBACK_SPLASH="/storage/roms/splash/exitsplash.png"
   fi

   if [ -z "${DURATION}" ] || [ ! -n ${DURATION} ]; then
     DURATION=0
   fi

   # if no is_image and no is_video.
   if is_image "${SPLASH}" == 1 && is_video "${SPLASH}" == 1; then
     SPLASH="${FALLBACK_SPLASH}"
   fi

   if is_image "${SPLASH}"; then
     if [ "${have_mpv}" -eq 1 ]; then
       ${PLAYER_IMG} --fullscreen --no-keepaspect --vf="${MPV_VF}" --image-display-duration=${DURATION} "${SPLASH}" >/dev/null 2>&1
     else
			 ffplay -fs -loglevel error -nostats -vf "${FILTER_FILL}" -i "${SPLASH}" -autoexit >/dev/null 2>&1
       sleep ${DURATION}
     fi
   elif is_video "${SPLASH}"; then
     if [ "${DURATION}" -eq 0 ]; then
       DURATION=3
     fi
     if [ "${PLAYER_VID}" = "ffplay" ]; then
       ${PLAYER_VID} -fs -autoexit -loglevel error -nostats -vf "${FILTER_FILL}" -t ${DURATION} -i "${SPLASH}" >/dev/null 2>&1
     else
       ${PLAYER_VID} --fullscreen --no-keepaspect --vf="${MPV_VF}" --length=${DURATION} "${SPLASH}" -t 1 >/dev/null 2>&1
     fi
   fi
 fi
else
  RND="$(get_ee_setting ee_randombootvideo.enabled)"
  if [ "${RND}" = "1" ]; then
    SPLASH="$(ls ${RANDOMVIDEO}/*.mp4 2>/dev/null | sort -R | tail -1)"
    [[ -z "${SPLASH}" ]] && SPLASH="${VIDEOSPLASH}"
  else
    SPLASH="${VIDEOSPLASH}"
  fi

  set_audio alsa

  if [ ${SS_DEVICE} -eq 1 ]; then
    ${PLAYER_VID} --fullscreen --no-keepaspect --vf="${MPV_VF}" "${SPLASH}" >/dev/null 2>&1
  else
    ${PLAYER_VID} -fs -autoexit -vf "${FILTER_FILL}" -i "${SPLASH}" >/dev/null 2>&1
  fi

  touch "/storage/.config/emuelec/configs/novideo"
fi

SPLASHTIME="$(get_ee_setting ee_splash.delay)"
[ -n "${SPLASHTIME}" ] && sleep "${SPLASHTIME}"