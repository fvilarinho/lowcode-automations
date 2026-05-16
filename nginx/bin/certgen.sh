#!/usr/bin/env bash

function prepareToExecute() {
  export CERTBOT_CMD=$(which certbot)
}

function checkDependencies() {
  if [ -z "$CERTBOT_CMD" ]; then
    echo "certbot is not installed! Please install it first to continue!"

    exit 1
  fi
}

function issue() {
  $CERTBOT_CMD certonly -d automation.vila.net.br --preferred-challenges dns-01 --manual -m me@vila.net.br
}

function sync() {
  cp -f /etc/letsencrypt/live/automation.vila.net.br/fullchain.pem ../etc/ssl/automation.pem
  cp -f /etc/letsencrypt/live/automation.vila.net.br/privkey.pem ../etc/ssl/automation.key
}

function main() {
  prepareToExecute
  checkDependencies
  issue
  sync
}

main
