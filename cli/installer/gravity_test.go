package installer

import (
	"os"
	"path"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func newGravity(t *testing.T, runner *fakeRunner) *Gravity {
	dir := t.TempDir()
	defaults := path.Join(dir, "default.list")
	require.NoError(t, os.WriteFile(defaults, []byte("https://lists.example/hosts\n\n# comment\n"), 0644))
	return &Gravity{
		Ftl:            "pihole-FTL",
		Db:             path.Join(dir, "gravity.db"),
		LegacyDb:       path.Join(dir, "legacy.db"),
		AdlistsFile:    path.Join(dir, "adlists.list"),
		DefaultAdlists: defaults,
		Runner:         runner,
	}
}

func touch(t *testing.T, file string) {
	require.NoError(t, os.WriteFile(file, []byte("db"), 0644))
}

func TestSeed_FreshInstallWritesAdlistsFile(t *testing.T) {
	runner := &fakeRunner{}
	g := newGravity(t, runner)

	require.NoError(t, g.Seed())

	content, err := os.ReadFile(g.AdlistsFile)
	require.NoError(t, err)
	assert.Contains(t, string(content), "https://lists.example/hosts")
	assert.Empty(t, runner.sql)
}

func TestSeed_EmptyDatabaseGetsDefaults(t *testing.T) {
	runner := &fakeRunner{count: "0"}
	g := newGravity(t, runner)
	touch(t, g.Db)

	require.NoError(t, g.Seed())

	assert.Equal(t, []string{"INSERT OR IGNORE INTO adlist (address) VALUES ('https://lists.example/hosts');"}, runner.sql)
}

func TestSeed_KeepsExistingAdlists(t *testing.T) {
	runner := &fakeRunner{count: "3"}
	g := newGravity(t, runner)
	touch(t, g.Db)

	require.NoError(t, g.Seed())

	assert.Empty(t, runner.sql)
}

func TestSeed_ImportsLegacyIntoExistingDatabase(t *testing.T) {
	runner := &fakeRunner{count: "6"}
	g := newGravity(t, runner)
	touch(t, g.Db)
	touch(t, g.LegacyDb)

	require.NoError(t, g.Seed())

	require.Len(t, runner.sql, 1)
	assert.Contains(t, runner.sql[0], "ATTACH DATABASE '"+g.LegacyDb+"' AS legacy;")
	assert.NoFileExists(t, g.LegacyDb)
}

func TestSeed_MovesLegacyIntoPlaceWithoutDatabase(t *testing.T) {
	runner := &fakeRunner{}
	g := newGravity(t, runner)
	touch(t, g.LegacyDb)

	require.NoError(t, g.Seed())

	assert.FileExists(t, g.Db)
	assert.NoFileExists(t, g.LegacyDb)
	assert.Empty(t, runner.sql)
}

func TestSeed_WaitsForDatabaseLock(t *testing.T) {
	runner := &fakeRunner{count: "0"}
	g := newGravity(t, runner)
	touch(t, g.Db)

	require.NoError(t, g.Seed())

	require.Len(t, runner.args, 2)
	for _, args := range runner.args {
		assert.Equal(t, []string{"sqlite3", "-cmd", ".timeout 30000", g.Db}, args[:4])
	}
}
