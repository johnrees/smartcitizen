#!/bin/sh
set -e

echo 1
# setup ssh-agent and provide the GitHub deploy key
eval "$(ssh-agent -s)"
#openssl aes-256-cbc -K $encrypted_fb17a912150b_key -iv $encrypted_fb17a912150b_iv -in ed25519.enc -out ed25519 -d
chmod 600 deploy_rsa
ssh-add deploy_rsa

echo 2
#ssh -p $PORT  $STAGING  "cd smartcitizen-api; ./scripts/deploy.sh"
ssh -p$PORT $SERVER touch file.txt
