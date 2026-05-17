#!/usr/bin/env bash

source /etc/camera/environment

$LSUSB_CMD | $GREP_CMD cam | $SED_CMD 's/.*ID [0-9a-fA-F:]* //'