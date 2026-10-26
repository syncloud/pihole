package installer

type Runner interface {
	Run(app string, args ...string) (string, error)
}
