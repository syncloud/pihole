package main

import (
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

func command() (string, []string) {
	if c := strings.TrimSpace(os.Getenv("GRAVITY_COMMAND")); c != "" {
		fields := strings.Fields(c)
		return fields[0], fields[1:]
	}
	return filepath.Join(os.Getenv("SNAP"), "bin", "pihole"), []string{"-g"}
}

func run(name string, args []string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stdout
	cmd.Env = os.Environ()
	return cmd.Run()
}

func main() {
	logger := log.New(os.Stdout, "gravity: ", log.LstdFlags|log.LUTC)
	name, args := command()
	logger.Printf("running %s %s", name, strings.Join(args, " "))
	start := time.Now()
	if err := run(name, args); err != nil {
		logger.Printf("update FAILED after %s: %v", time.Since(start).Round(time.Second), err)
		os.Exit(1)
	}
	logger.Printf("update completed in %s", time.Since(start).Round(time.Second))
}
