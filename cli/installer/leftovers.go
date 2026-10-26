package installer

import (
	"errors"
	"os"
	"path/filepath"
	"syscall"

	"go.uber.org/zap"
)

type Leftovers struct {
	Patterns  []string
	EmptyDirs []string
	Logger    *zap.Logger
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
	for _, dir := range l.EmptyDirs {
		err := os.Remove(dir)
		if err != nil && !errors.Is(err, os.ErrNotExist) && !errors.Is(err, syscall.ENOTEMPTY) && !errors.Is(err, syscall.EEXIST) {
			return err
		}
	}
	return nil
}
