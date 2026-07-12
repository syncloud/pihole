package main

import (
	"os"

	"go.uber.org/zap"
	"hooks/installer"
	"hooks/log"
)

func main() {
	logger := log.Logger(zap.DebugLevel)
	logger.Info("install")
	if err := installer.New(logger).Install(); err != nil {
		logger.Error("install failed", zap.Error(err))
		os.Exit(1)
	}
}
