package main

import (
	"os"
	"os/exec"
	"path"
	"time"

	"go.uber.org/zap"
	"hooks/log"
)

const interval = time.Hour

func main() {
	logger := log.Logger(zap.DebugLevel)
	gravity := path.Join(os.Getenv("SNAP"), "bin", "gravity.sh")
	for {
		logger.Info("running gravity")
		cmd := exec.Command(gravity)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			logger.Error("gravity failed", zap.Error(err))
		}
		time.Sleep(interval)
	}
}
