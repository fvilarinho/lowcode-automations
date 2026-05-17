#!/usr/bin/env bash

source /etc/camera/environment

echo -n "{\"model\": \"$($INSTALL_DIR/model.sh)\", "
echo -n "\"cpu\": \"$($INSTALL_DIR/cpu.sh)\", "
echo -n "\"memory\": \"$($INSTALL_DIR/memory.sh)\", "
echo -n "\"disk\": \"$($INSTALL_DIR/disk.sh)\", "
echo -n "\"temp\": \"$($INSTALL_DIR/temp.sh)\", "
echo -n "\"state\": \""

IS_ON=$($INSTALL_DIR/motion/checkIfItsOn.sh)

if [ $IS_ON == true ]; then
   echo -n "on"
else
   echo -n "off"
fi

echo -n "\"}"
