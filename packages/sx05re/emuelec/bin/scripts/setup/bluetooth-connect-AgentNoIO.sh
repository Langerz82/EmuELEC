#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

PROC_NAME="ee-bt-nino"

ee_console disable
ee_console enable

gptokeyb -1 "${PROC_NAME}" -killsignal 15 && pkill emuelec-bluetoo && pkill gptokeyb &

bash -c "exec -a ${PROC_NAME} emuelec-bluetooth-NoInputNoOutput" && pkill gptokeyb &

wait

exit 0
