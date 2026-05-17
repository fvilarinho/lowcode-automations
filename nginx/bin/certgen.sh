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
  $CERTBOT_CMD certonly -d "$AUTOMATION_SERVER_DOMAIN" --preferred-challenges dns-01 --manual -m "$CERTGEN_EMAIL"
}

function sync() {
  cp -f "/etc/letsencrypt/live/$AUTOMATION_SERVER_DOMAIN/fullchain.pem" ../etc/ssl/automation.pem
  cp -f "/etc/letsencrypt/live/$AUTOMATION_SERVER_DOMAIN/privkey.pem" ../etc/ssl/automation.key
}

function main() {
  prepareToExecute
  checkDependencies
  issue
  sync
}

main
