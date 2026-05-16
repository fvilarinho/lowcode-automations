#!/usr/bin/env bash

function prepareToExecute() {
  export DOCKER_CMD=$(which docker)
}

function checkDependencies() {
  if [ -z "$DOCKER_CMD" ]; then
    echo "docker is not installed! Please install it first to continue!"

    exit 1
  fi
}

function start() {
  $DOCKER_CMD compose up -d
}

function main() {
  prepareToExecute
  checkDependencies
  start
}

main

