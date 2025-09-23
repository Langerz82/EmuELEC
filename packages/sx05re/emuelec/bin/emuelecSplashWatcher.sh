#!/bin/bash

SPLASH_PID=$(cat /tmp/splash_pid)
PID=$(cat /tmp/emuelecRun_pid)

[[ -z "${SPLASH_PID}" ]] && exit 0
[[ -z "${PID}" ]] && exit 0

pgrep -P ${PID} > /tmp/ee_processes

ignore_list=(
	"/usr/bin/gptokeyb"
	"/usr/bin/bash"
	"/usr/bin/sh"
)

while true; do
	while read line; do
		LAST_PROCESS=$(lsof | grep -e "^${line}.*$" | tail -n 1 )
		LAST_PID=$( echo "${LAST_PROCESS}" | cut -f1 )
		LAST_PID_NAME=$( echo "${LAST_PROCESS}" | cut -f2 )
		if [[ "/usr/bin/bash" == *${LAST_PID_NAME}* ]] || [[ "/usr/bin/sh" == *${LAST_PID_NAME}* ]]; then
			pgrep -P ${LAST_PID} > /tmp/ee_processes
			break
		fi
		if [[ ! " ${ignore_list[*]} " == *${LAST_PID_NAME}* ]]; then
			ACCESSING_FB=$( lsof | grep -e "^${LAST_PID}.*$" | grep -e "/dev/fb[0-3]*" )
			if [[ ! -z "${ACCESSING_FB}" ]]; then
				echo "killing ${SPLASH_PID}"
				kill -9 ${SPLASH_PID} && exit 0
			fi
		fi
	done < /tmp/ee_processes
	sleep 0.1
done
