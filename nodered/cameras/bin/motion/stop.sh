#!/usr/bin/env bash

source /etc/camera/environment

pkill -9 motion

pwd="$INSTALL_DIR/motion"

rm -f "$pwd/motion.log"
rm -f "$pwd/motion.conf"