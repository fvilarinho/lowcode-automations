#!/bin/bash

TERRAFORM_CMD=$(which terraform)

cd iac || exit 1

$TERRAFORM_CMD init -migrate-state -upgrade || exit 1
$TERRAFORM_CMD plan -out=/tmp/camera.plan || exit 1
$TERRAFORM_CMD apply /tmp/camera.plan || exit 1

rm -f /tmp/camera.plan