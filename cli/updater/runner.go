package updater

type Runner interface {
	Run(app string, args ...string) (string, error)
}
