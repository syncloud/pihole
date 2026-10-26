package updater

import (
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"go.uber.org/zap"
)

func newUpdater(runner *fakeRunner) *Updater {
	return &Updater{
		Gravity:  "gravity.sh",
		Pihole:   "pihole.sh",
		Runner:   runner,
		Interval: 7 * 24 * time.Hour,
		Retry:    time.Minute,
		MaxRetry: 3 * time.Minute,
		Logger:   zap.NewNop(),
	}
}

func TestNext_BacksOffOnFailureAndResetsOnSuccess(t *testing.T) {
	offline := errors.New("offline")
	u := newUpdater(&fakeRunner{gravityErrors: []error{offline, offline, offline, nil, offline}})

	assert.Equal(t, time.Minute, u.Next())
	assert.Equal(t, 2*time.Minute, u.Next())
	assert.Equal(t, 3*time.Minute, u.Next())
	assert.Equal(t, 7*24*time.Hour, u.Next())
	assert.Equal(t, time.Minute, u.Next())
}

func TestNext_ReloadsListsOnlyAfterSuccessfulGravity(t *testing.T) {
	runner := &fakeRunner{gravityErrors: []error{errors.New("offline"), nil}}
	u := newUpdater(runner)

	u.Next()
	u.Next()

	assert.Equal(t, []string{"gravity.sh", "gravity.sh", "pihole.sh reloadlists"}, runner.calls)
}
