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
	pihole := path.Join(os.Getenv("SNAP"), "bin", "pihole.sh")
	u := &updater.Updater{
		Run: func() error {
			logger.Info("running gravity")
			if err := run(gravity); err != nil {
				return err
			}
			return run(pihole, "reloadlists")
		},
		Sleep:    time.Sleep,
		Interval: 7 * 24 * time.Hour,
		Retry:    time.Minute,
		MaxRetry: time.Hour,
		Logger:   logger,
	}
	u.Loop()
}

func run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
