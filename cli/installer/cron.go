package installer

import (
	"fmt"
	"os/exec"
	"strings"

	"go.uber.org/zap"
)

type Cron struct {
	user    string
	command string
	logger  *zap.Logger
}

func NewCron(user string, logger *zap.Logger) *Cron {
	return &Cron{
		user:    user,
		command: fmt.Sprintf("/usr/bin/snap run %s.cron", App),
		logger:  logger,
	}
}

func (c *Cron) Create() error {
	c.logger.Info("creating crontab task")
	if err := c.Remove(); err != nil {
		return err
	}
	existing := ""
	out, err := exec.Command("crontab", "-u", c.user, "-l").CombinedOutput()
	if err == nil {
		existing = strings.TrimRight(string(out), "\n")
	}
	entry := fmt.Sprintf("59 1 * * 7 %s", c.command)
	if existing == "" {
		return c.write(entry + "\n")
	}
	return c.write(existing + "\n" + entry + "\n")
}

func (c *Cron) Remove() error {
	out, err := exec.Command("crontab", "-u", c.user, "-l").CombinedOutput()
	if err != nil {
		return nil
	}
	var kept []string
	for _, line := range strings.Split(string(out), "\n") {
		if !strings.Contains(line, c.command) {
			kept = append(kept, line)
		}
	}
	return c.write(strings.Join(kept, "\n"))
}

func (c *Cron) write(content string) error {
	cmd := exec.Command("crontab", "-u", c.user, "-")
	cmd.Stdin = strings.NewReader(content)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("crontab write failed: %w: %s", err, string(out))
	}
	return nil
}
