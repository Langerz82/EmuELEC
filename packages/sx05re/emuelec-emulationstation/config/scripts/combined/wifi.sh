#!/bin/bash

## This is an example combined script for all events that ES triggers
## options separated with , are secondary arguments e.g (arg1; arg2; arg3)
## options separated with ; are single argument to choose from e.g (arg1, arg1, arg1)
#
# start
# game-start (rom, basename, name)
# game-end
# system-selected (name)
# game-selected (system-name, game-path, name)
# screensaver-start (screensaver_behavior)
# screensaver-stop
# theme-changed (new-theme, old-theme)
# sleep
# wake
# config-changed
# controls-changed
# settings-changed
# quit (and any one of these as second argument: restart; reboot; shutdown; nand; retroarch)


. /etc/profile

EVENT=${1}
shift

event_wake() {
  local SSID=$(get_ee_setting wifi.ssid)
  local KEY=$(get_ee_setting wifi.key)
  local ENABLED=$(get_ee_setting wifi.enabled)

  if [[ "${ENABLED}" == "1" ]];
    batocera-config wifi enable "${SSID}" "${KEY}"
  fi
}

case "${EVENT}" in
    "wake")
	event_wake
	;;
    # and so and and so fort
    *)
	exit 1
esac

## You could also do something like this:

# event_${1} ${2} ${3} ${4}

## To call the event directly, but you need error checking.

exit 0
