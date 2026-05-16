#!/usr/bin/env bash

source /etc/camera/environment

pwd="$INSTALL_DIR/motion"

eval "$pwd/stop.sh"

devices=($(ls /dev/video*))
deviceId=${devices[0]}
templateFilename=$pwd/motion.conf.template
configFilename=$pwd/motion.conf

cp -f "$templateFilename" "$configFilename"
$SED_CMD -i -e 's|${DEVICE_ID}|'"$deviceId"'|g' "$configFilename"
$MOTION_CMD -b -c $pwd/motion.conf -l $pwd/motion.log