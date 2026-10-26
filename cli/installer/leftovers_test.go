package installer

import (
	"os"
	"path"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

func TestLeftovers_RemovesMatchesOnly(t *testing.T) {
	dir := t.TempDir()
	for _, name := range []string{"pihole-FTL.db", "list.1.example.domains", "list.1.example.domains.sha1", "adlists.list"} {
		require.NoError(t, os.WriteFile(path.Join(dir, name), []byte("x"), 0644))
	}
	leftovers := &Leftovers{
		Patterns: []string{path.Join(dir, "pihole-FTL.db"), path.Join(dir, "list.*.domains*"), path.Join(dir, "missing")},
		Logger:   zap.NewNop(),
	}

	require.NoError(t, leftovers.Remove())

	assert.NoFileExists(t, path.Join(dir, "pihole-FTL.db"))
	assert.NoFileExists(t, path.Join(dir, "list.1.example.domains"))
	assert.NoFileExists(t, path.Join(dir, "list.1.example.domains.sha1"))
	assert.FileExists(t, path.Join(dir, "adlists.list"))
}

func TestLeftovers_RemovesOnlyEmptyDirs(t *testing.T) {
	dir := t.TempDir()
	empty := path.Join(dir, "empty")
	full := path.Join(dir, "full")
	require.NoError(t, os.Mkdir(empty, 0755))
	require.NoError(t, os.Mkdir(full, 0755))
	require.NoError(t, os.WriteFile(path.Join(full, "keep"), []byte("x"), 0644))
	leftovers := &Leftovers{EmptyDirs: []string{empty, full, path.Join(dir, "missing")}, Logger: zap.NewNop()}

	require.NoError(t, leftovers.Remove())

	assert.NoDirExists(t, empty)
	assert.FileExists(t, path.Join(full, "keep"))
}
