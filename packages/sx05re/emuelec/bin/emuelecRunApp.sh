#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

# Source predefined functions and variables
. /etc/profile

# DO NOT modify this file, if you need to use autostart please use /storage/.config/custom_start.sh 

PLATFORM="${2:2}"

emuelec-utils init_app_video ${PLATFORM} "${1}"

eval /usr/bin/bash $@

emuelec-utils end_app_video
