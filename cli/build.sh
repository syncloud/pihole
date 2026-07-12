#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BIN_OUT=${DIR}/../build/snap/bin
HOOKS_OUT=${DIR}/../build/snap/meta/hooks
mkdir -p ${BIN_OUT} ${HOOKS_OUT}

go vet ./...
CGO_ENABLED=0 go build -ldflags "-s -w" -o ${BIN_OUT}/cli ./cmd/cli
CGO_ENABLED=0 go build -ldflags "-s -w" -o ${HOOKS_OUT}/install ./cmd/install
CGO_ENABLED=0 go build -ldflags "-s -w" -o ${HOOKS_OUT}/configure ./cmd/configure
