package installer

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Gravity struct {
	Ftl            string
	Db             string
	LegacyDb       string
	AdlistsFile    string
	DefaultAdlists string
	Runner         Runner
}

func (g *Gravity) Seed() error {
	if exists(g.LegacyDb) {
		if !exists(g.Db) {
			return os.Rename(g.LegacyDb, g.Db)
		}
		if err := g.importLegacy(); err != nil {
			return fmt.Errorf("import %s: %w", g.LegacyDb, err)
		}
		if err := os.Remove(g.LegacyDb); err != nil {
			return err
		}
	}
	if !exists(g.Db) {
		return g.writeAdlistsFile()
	}
	count, err := g.adlistCount()
	if err != nil {
		return err
	}
	if count > 0 {
		return nil
	}
	return g.insertDefaults()
}

func (g *Gravity) importLegacy() error {
	return g.exec(fmt.Sprintf(
		"ATTACH DATABASE '%s' AS legacy;"+
			" INSERT OR IGNORE INTO adlist (address, enabled, comment) SELECT address, enabled, comment FROM legacy.adlist;"+
			" INSERT OR IGNORE INTO domainlist (type, domain, enabled, comment) SELECT type, domain, enabled, comment FROM legacy.domainlist;",
		g.LegacyDb))
}

func (g *Gravity) adlistCount() (int, error) {
	out, err := g.Runner.Run(g.Ftl, "sqlite3", g.Db, "SELECT count(*) FROM adlist;")
	if err != nil {
		return 0, fmt.Errorf("count adlists: %w: %s", err, out)
	}
	return strconv.Atoi(strings.TrimSpace(out))
}

func (g *Gravity) insertDefaults() error {
	addresses, err := g.defaultAddresses()
	if err != nil {
		return err
	}
	var statements []string
	for _, address := range addresses {
		statements = append(statements, fmt.Sprintf("INSERT OR IGNORE INTO adlist (address) VALUES ('%s');", address))
	}
	return g.exec(strings.Join(statements, " "))
}

func (g *Gravity) writeAdlistsFile() error {
	if exists(g.AdlistsFile) {
		return nil
	}
	content, err := os.ReadFile(g.DefaultAdlists)
	if err != nil {
		return err
	}
	return os.WriteFile(g.AdlistsFile, content, 0644)
}

func (g *Gravity) defaultAddresses() ([]string, error) {
	file, err := os.Open(g.DefaultAdlists)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	var addresses []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") || strings.ContainsRune(line, '\'') {
			continue
		}
		addresses = append(addresses, line)
	}
	return addresses, scanner.Err()
}

func (g *Gravity) exec(sql string) error {
	out, err := g.Runner.Run(g.Ftl, "sqlite3", g.Db, sql)
	if err != nil {
		return fmt.Errorf("%w: %s", err, out)
	}
	return nil
}

func exists(file string) bool {
	_, err := os.Stat(file)
	return err == nil
}
