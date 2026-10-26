package main

import (
	"os"

	"go.uber.org/zap"
	"hooks/installer"
	"hooks/log"
)

func main() {
	logger := log.Logger(zap.DebugLevel)
	logger.Info("post-refresh")
	if err := installer.New(logger).PostRefresh(); err != nil {
		logger.Error("post-refresh failed", zap.Error(err))
		os.Exit(1)
	}
}
