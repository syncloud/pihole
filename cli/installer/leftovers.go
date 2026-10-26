package installer

import (
	"os"
	"path/filepath"

	"go.uber.org/zap"
)

type Leftovers struct {
	Patterns []string
	Logger   *zap.Logger
}

func (l *Leftovers) Remove() error {
	for _, pattern := range l.Patterns {
		matches, err := filepath.Glob(pattern)
		if err != nil {
			return err
		}
		for _, match := range matches {
			l.Logger.Info("removing leftover", zap.String("path", match))
			if err := os.RemoveAll(match); err != nil {
				return err
			}
		}
	}
	return nil
}
