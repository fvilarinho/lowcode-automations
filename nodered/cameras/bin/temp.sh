#!/usr/bin/env bash

source /etc/camera/environment

echo $($VCGEN_CMD measure_temp | $AWK_CMD -F '=' '{print $2}')
