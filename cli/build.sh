#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

OUT=${DIR}/../build/cli
HOOKS_OUT=${DIR}/../build/snap/meta/hooks
mkdir -p ${OUT} ${HOOKS_OUT}

go vet ./...
CGO_ENABLED=0 go build -ldflags "-s -w" -o ${OUT}/cli ./cmd/cli
CGO_ENABLED=0 go build -ldflags "-s -w" -o ${HOOKS_OUT}/install ./cmd/install
CGO_ENABLED=0 go build -ldflags "-s -w" -o ${HOOKS_OUT}/configure ./cmd/configure
