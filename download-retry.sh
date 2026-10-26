#!/bin/bash -e

URL=$1
TARGET=$2

for i in $(seq 1 10); do
  if wget --progress=dot:giga --tries=3 --timeout=60 "${URL}" -O "${TARGET}"; then
    exit 0
  fi
  echo "retry download ${URL}"
  sleep 10
done

echo "failed to download ${URL}"
exit 1
