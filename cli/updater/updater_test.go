package updater

import (
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"go.uber.org/zap"
)

func TestNext_BacksOffOnFailureAndResetsOnSuccess(t *testing.T) {
	results := []error{errors.New("offline"), errors.New("offline"), errors.New("offline"), nil, errors.New("offline")}
	u := &Updater{
		Run: func() error {
			result := results[0]
			results = results[1:]
			return result
		},
		Interval: 7 * 24 * time.Hour,
		Retry:    time.Minute,
		MaxRetry: 3 * time.Minute,
		Logger:   zap.NewNop(),
	}

	assert.Equal(t, time.Minute, u.Next())
	assert.Equal(t, 2*time.Minute, u.Next())
	assert.Equal(t, 3*time.Minute, u.Next())
	assert.Equal(t, 7*24*time.Hour, u.Next())
	assert.Equal(t, time.Minute, u.Next())
}
