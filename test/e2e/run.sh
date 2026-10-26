#!/bin/bash -e

DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

SPEC=$1

export PLAYWRIGHT_FULL_DOMAIN=buster.com
export PLAYWRIGHT_APP_DOMAIN=pihole.buster.com
export PLAYWRIGHT_DEVICE_USER=user
export PLAYWRIGHT_DEVICE_PASSWORD=Password1
export PLAYWRIGHT_PROJECT=desktop
export PLAYWRIGHT_ARTIFACT_DIR=/drone/src/artifact/screenshots

getent hosts $PLAYWRIGHT_APP_DOMAIN | sed "s/$PLAYWRIGHT_APP_DOMAIN/auth.$PLAYWRIGHT_FULL_DOMAIN/g" | tee -a /etc/hosts

${DIR}/../../apt.sh curl
${DIR}/wait-app.sh ${PLAYWRIGHT_APP_DOMAIN}
for i in $(seq 1 5); do
  if npm ci --no-audit --no-fund; then
    break
  fi
  if [ $i -eq 5 ]; then
    echo "npm ci failed"
    exit 1
  fi
  echo "retry npm ci"
  sleep 10
done
npx playwright test --project=${PLAYWRIGHT_PROJECT} "$SPEC"
