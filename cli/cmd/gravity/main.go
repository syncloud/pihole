package main

import (
	"os"
	"os/exec"
	"path"
	"time"

	"go.uber.org/zap"
	"hooks/log"
	"hooks/updater"
)

func main() {
	logger := log.Logger(zap.DebugLevel)
	gravity := path.Join(os.Getenv("SNAP"), "bin", "gravity.sh")
	u := &updater.Updater{
		Run: func() error {
			logger.Info("running gravity")
			cmd := exec.Command(gravity)
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			return cmd.Run()
		},
		Sleep:    time.Sleep,
		Interval: 7 * 24 * time.Hour,
		Retry:    time.Minute,
		MaxRetry: time.Hour,
		Logger:   logger,
	}
	u.Loop()
}
