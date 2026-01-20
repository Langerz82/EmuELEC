#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

ee_console disable
ee_console enable

gptokeyb -customkill "pkill emuelec-bluetoo" &

emuelec-bluetooth-NoInputNoOutput

killall gptokeyb

exit 0
