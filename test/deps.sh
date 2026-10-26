#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

${DIR}/../apt.sh sshpass openssh-client curl
for i in $(seq 1 10); do
  if pip install -r ${DIR}/requirements.txt; then
    exit 0
  fi
  echo "retry pip"
  sleep 5
done
echo "pip failed"
exit 1
