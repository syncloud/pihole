#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

OUT=${DIR}/../build/gravity
mkdir -p ${OUT}

go test ./...
CGO_ENABLED=0 go build -ldflags "-s -w" -o ${OUT}/gravity .
