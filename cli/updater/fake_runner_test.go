package updater

import "strings"

type fakeRunner struct {
	gravityErrors []error
	calls         []string
}

func (f *fakeRunner) Run(app string, args ...string) (string, error) {
	f.calls = append(f.calls, strings.Join(append([]string{app}, args...), " "))
	if app != "gravity.sh" {
		return "", nil
	}
	err := f.gravityErrors[0]
	f.gravityErrors = f.gravityErrors[1:]
	return "", err
}
