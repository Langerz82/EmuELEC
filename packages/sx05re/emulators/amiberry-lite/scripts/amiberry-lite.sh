#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 0riginally created by Escalade (https://github.com/escalade)
# Copyright (C) 2018-present 5schatten (https://github.com/5schatten)
# Copyright (C) 2025-present Langerz82 (https://github.com/Langerz82)

. /etc/profile

# Set some common variables
AMIBERRY_DIR=/storage/.config/amiberry-lite
AMIBERRY_CONFIG_DIR=$AMIBERRY_DIR/conf
AMIBERRY_TMP_DIR=/tmp/emulation/amiberry-lite
AMIBERRY_TMP_CONFIG="${AMIBERRY_TMP_DIR}"/.amiberry_conf.uae
AMIBERRY_LOG=/emuelec/logs/amiberry-lite.log
MAX_DRIVES=4
i=0

echo "EmuELEC Amiberry-lite Log" > "${AMIBERRY_LOG}"

# Set SDL audio driver to alsa
SDL_AUDIODRIVER=alsa

# Which file should amiberry load?
echo "Trying to boot this game:" "$1" >> ${AMIBERRY_LOG}

# Change working directory cause amiberry loads assets from there
cd ${AMIBERRY_DIR}

# Create a clean working directory
if [ -d "${AMIBERRY_TMP_DIR}" ]; then
  echo "Clean up old working directory." >> ${AMIBERRY_LOG}
  rm -rf "${AMIBERRY_TMP_DIR}"
fi
mkdir -p "${AMIBERRY_TMP_DIR}"

# Check if the file is an Amiga 1200/CD32 game and set configuration options for an Amiga 1200
AMIBERRY_SET_MODEL() {
	local MODEL=A500
	if [ `echo $1 | grep -e 'AGA' | wc -l` -eq 1 -o `echo "${AMIBERRY_TMP_DIR}"/* | grep -e 'AGA' | wc -l` -eq 1 ] || [[ "$1" = */amiga1200/* ]]; then
		MODEL=A1200
  elif [ `echo $1 | grep -e 'CD32' | wc -l` -eq 1 -o `echo "${AMIBERRY_TMP_DIR}"/* | grep -e 'CD32' | wc -l` -eq 1 ] || [[ "$1" = */cd32/* ]]; then
		MODEL=CD32
  fi
	echo ${MODEL}
}

AMIBERRY_SET_CONF() {
	local CONFIG_FILE="${AMIBERRY_DIR}/conf/Amiga${1}-custom.uae"
	if [[ -f "${CONFIG_FILE}" ]]; then
		cp ${CONFIG_FILE} "${AMIBERRY_TMP_CONFIG}"
		echo -f "${AMIBERRY_TMP_CONFIG}"
	fi
	CONFIG_FILE="${AMIBERRY_DIR}/conf/custom.uae"
	if [[ -f "${CONFIG_FILE}" ]]; then
		cp ${CONFIG_FILE} "${AMIBERRY_TMP_CONFIG}"
		echo -f "${AMIBERRY_TMP_CONFIG}"
	fi
	echo ""
}

AMIBERRY_GET_ARGS() {
	local MODEL=$( AMIBERRY_SET_MODEL "${1}" )
	local CONF_ARG=$( AMIBERRY_SET_CONF ${MODEL} )
	if [[ -z ${CONF_ARG} ]]; then
		CONF_ARG="--model ${MODEL} -G ${AMIBERRY_ADD_ARGS}"
	fi
#	echo ${CONF_ARG} --log -s use_gui=yes -s start_minimized=no -s default_fullscreen_mode=1 -s gui_always_on_top=no
	echo ${CONF_ARG} --log ${2}
}

AMIBERRY_ADD_ARGS="${2}"

# Check if we are loading a .zip file
if [ `echo $1 | grep -i .zip | wc -l` -eq 1 ]; then
  
  # Unpack the zip file
  unzip -q -o "$1" -d "${AMIBERRY_TMP_DIR}"
  
  if [ -f "${AMIBERRY_TMP_DIR}"/*.*nfo ] && [ -f "${AMIBERRY_TMP_DIR}"/*/*.*lave ]; then

    # WHDLoad file detected
    echo "Loading a WHDLoad (.zip) file..." >> ${AMIBERRY_LOG}

		AMIBERRY_ARGS=$( AMIBERRY_GET_ARGS "${1}" )

    amiberry-lite ${AMIBERRY_ARGS} -autoload "$1" >> ${AMIBERRY_LOG} 2>&1

  else
    # .zip file detected
    echo "Loading a .zip file..." >> ${AMIBERRY_LOG}

		AMIBERRY_ARGS=$( AMIBERRY_GET_ARGS "${1}" )

    # Assign files to floppy0-3
		FLOPPY_FILE=/tmp/emulation/amiberry_floppy
		
		FLOPPY_ARG=()
		i=0
    for FILE in "${AMIBERRY_TMP_DIR}"/*
    do
      FLOPPY_ARG+=(-${i} "${FILE}")
      i=$(($i+1))
      # This emulator supports 4 floppies max
      if [ ${i} -eq ${MAX_DRIVES} ]; then
        break;
      fi
    done
#		TMP="${FLOPPY_ARG[@]}"

		amiberry-lite ${AMIBERRY_ARGS} "${FLOPPY_ARG[@]}" >> ${AMIBERRY_LOG} 2>&1
  fi

# Check for WHDload files (.lha)
elif [ `echo $1 | grep -i .lha | wc -l` -eq 1 ]; then
    
  #.lha file detected
  echo "Loading a WHDLoad (.lha) file..." >> ${AMIBERRY_LOG}

	AMIBERRY_ARGS=$( AMIBERRY_GET_ARGS "${1}" )

	amiberry-lite ${AMIBERRY_ARGS} --autoload "$1" >> ${AMIBERRY_LOG} 2>&1

# Check for .uae config file
elif [ `echo $1 | grep -i .uae | wc -l` -eq 1 ]; then

  # .uae file detected
  echo "Loading an .uae file..." >> ${AMIBERRY_LOG}

	AMIBERRY_ARGS=$( AMIBERRY_GET_ARGS "${1}" )

  # Load .uae config file
  amiberry-lite ${AMIBERRY_ARGS} -f "$1" >> ${AMIBERRY_LOG} 2>&1

# All other files (.adf .adz .ipf)
else

  #.adf or .adz or .ipf file detected
  echo "Loading a single .adf or .adz or .ipf file..." >> ${AMIBERRY_LOG}

	AMIBERRY_ARGS=$( AMIBERRY_GET_ARGS "${1}" )

	amiberry-lite ${AMIBERRY_ARGS} -0 "${1}" >> ${AMIBERRY_LOG} 2>&1
fi

# Remove temporary dir
rm -rf "${AMIBERRY_TMP_DIR}"
