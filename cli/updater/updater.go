package updater

import (
	"fmt"
	"time"

	"go.uber.org/zap"
)

type Updater struct {
	Gravity  string
	Pihole   string
	Runner   Runner
	Interval time.Duration
	Retry    time.Duration
	MaxRetry time.Duration
	Logger   *zap.Logger
	backoff  time.Duration
}

func (u *Updater) Loop() {
	for {
		time.Sleep(u.Next())
	}
}

func (u *Updater) Next() time.Duration {
	if err := u.update(); err != nil {
		if u.backoff == 0 {
			u.backoff = u.Retry
		} else if u.backoff < u.MaxRetry {
			u.backoff = min(u.backoff*2, u.MaxRetry)
		}
		u.Logger.Error("gravity failed", zap.Error(err), zap.Duration("retry", u.backoff))
		return u.backoff
	}
	u.backoff = 0
	return u.Interval
}

func (u *Updater) update() error {
	u.Logger.Info("running gravity")
	if out, err := u.Runner.Run(u.Gravity); err != nil {
		return fmt.Errorf("gravity: %w: %s", err, out)
	}
	if out, err := u.Runner.Run(u.Pihole, "reloadlists"); err != nil {
		return fmt.Errorf("reload lists: %w: %s", err, out)
	}
	return nil
}
