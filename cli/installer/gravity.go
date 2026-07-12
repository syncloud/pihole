package installer

import (
	"os"
	"os/exec"
	"path"
	"time"

	"go.uber.org/zap"
)

const GravityInterval = time.Hour

func GravityLoop(logger *zap.Logger) error {
	gravity := path.Join(os.Getenv("SNAP"), "bin", "gravity.sh")
	for {
		logger.Info("running gravity")
		cmd := exec.Command(gravity)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			logger.Error("gravity failed", zap.Error(err))
		}
		time.Sleep(GravityInterval)
	}
}
