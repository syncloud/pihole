package installer

import "strings"

type fakeRunner struct {
	count string
	sql   []string
}

func (f *fakeRunner) Run(_ string, args ...string) (string, error) {
	query := args[len(args)-1]
	if strings.HasPrefix(query, "SELECT count(*)") {
		return f.count + "\n", nil
	}
	f.sql = append(f.sql, query)
	return "", nil
}
