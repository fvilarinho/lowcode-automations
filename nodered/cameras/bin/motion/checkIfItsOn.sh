#!/usr/bin/env bash

source /etc/camera/environment

value=$(ps -def | $AWK_CMD {'print $8'} | $GREP_CMD motion)

if [ -n "$value" ]; then
	 echo true
else
	 echo false
fi
