#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

OUT=${DIR}/../build/cli
mkdir -p ${OUT}

go vet ./...
CGO_ENABLED=0 go build -ldflags "-s -w" -o ${OUT}/cli ./cmd/cli
