package main

import (
	"os"
	"path"
	"time"

	"go.uber.org/zap"
	"hooks/installer"
	"hooks/log"
	"hooks/updater"
)

func main() {
	logger := log.Logger(zap.DebugLevel)
	u := &updater.Updater{
		Gravity:  path.Join(os.Getenv("SNAP"), "bin", "gravity.sh"),
		Pihole:   path.Join(os.Getenv("SNAP"), "bin", "pihole.sh"),
		Runner:   installer.NewExecutor(logger),
		Interval: 7 * 24 * time.Hour,
		Retry:    time.Minute,
		MaxRetry: time.Hour,
		Logger:   logger,
	}
	u.Loop()
}
