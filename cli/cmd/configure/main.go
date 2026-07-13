package main

import (
	"os"

	"go.uber.org/zap"
	"hooks/installer"
	"hooks/log"
)

func main() {
	logger := log.Logger(zap.DebugLevel)
	logger.Info("configure")
	if err := installer.New(logger).Configure(); err != nil {
		logger.Error("configure failed", zap.Error(err))
		os.Exit(1)
	}
}
