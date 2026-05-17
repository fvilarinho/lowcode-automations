#!/usr/bin/env bash

source /etc/camera/environment

echo $($DF_CMD -h | $GREP_CMD /dev/mmcblk0p2 | $AWK_CMD '{print $5}')