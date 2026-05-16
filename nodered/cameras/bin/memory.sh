#!/bin/bash

source /etc/camera/environment

value=$($FREE_CMD | $GREP_CMD Mem: | $AWK_CMD {'print (($3/$2)*100)'})

echo "$value%"
