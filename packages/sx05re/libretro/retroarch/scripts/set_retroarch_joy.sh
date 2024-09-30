#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

source joy_common.sh "retroarch"

clean_pad () {
		return
}

# Sets pad depending on parameters.
# ${1} = Player Number
# ${2} = js[0-7]
# ${3} = Device GUID
# ${4} = Device Name

set_pad() {
  local DEVICE_GUID=${3}
  local JOY_NAME="${4}"

  echo "DEVICE_GUID=${DEVICE_GUID}"

  local GC_CONFIG=$(cat "${GCDB}" | grep "${DEVICE_GUID}" | grep "platform:Linux" | head -1)
	local JOY_NAME_2=$(echo ${GC_CONFIG} | cut -d',' -f2)
	if [[ "${JOY_NAME}" != "${JOY_NAME_2}" ]]; then
		cp "/tmp/joypads/${JOY_NAME_2}.cfg" "/tmp/joypads/${JOY_NAME}.cfg"
	fi

}

jc_get_players
