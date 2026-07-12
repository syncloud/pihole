#!/bin/bash -e
DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

ARTIFACT_SUBDIR=$1
SPEC=$2
PROJECT=${3:-desktop}

export PLAYWRIGHT_FULL_DOMAIN=buster.com
export PLAYWRIGHT_APP_DOMAIN=pihole.buster.com
export PLAYWRIGHT_DEVICE_HOST=pihole.buster.com
export PLAYWRIGHT_DEVICE_USER=user
export PLAYWRIGHT_DEVICE_PASSWORD=Password1
export PLAYWRIGHT_SSH_USER=root
export PLAYWRIGHT_SSH_PASSWORD=Password1
export PLAYWRIGHT_PROJECT=${PROJECT}
export PLAYWRIGHT_ARTIFACT_DIR=/drone/src/artifact/${ARTIFACT_SUBDIR}

getent hosts $PLAYWRIGHT_APP_DOMAIN | sed "s/$PLAYWRIGHT_APP_DOMAIN/auth.$PLAYWRIGHT_FULL_DOMAIN/g" | tee -a /etc/hosts

apt-get update -qq
apt-get install -y -qq sshpass openssh-client curl
npm install --no-audit --no-fund
npx playwright test --project="${PROJECT}" ${SPEC}
