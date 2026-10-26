package updater

import (
	"time"

	"go.uber.org/zap"
)

type Updater struct {
	Run      func() error
	Sleep    func(time.Duration)
	Interval time.Duration
	Retry    time.Duration
	MaxRetry time.Duration
	Logger   *zap.Logger
	backoff  time.Duration
}

func (u *Updater) Loop() {
	for {
		u.Sleep(u.Next())
	}
}

func (u *Updater) Next() time.Duration {
	if err := u.Run(); err != nil {
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
