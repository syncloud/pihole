package main

import (
	"testing"
)

func TestCommandDefault(t *testing.T) {
	t.Setenv("GRAVITY_COMMAND", "")
	t.Setenv("SNAP", "/snap/pihole/current")
	name, args := command()
	if name != "/snap/pihole/current/bin/pihole.sh" {
		t.Fatalf("unexpected name: %s", name)
	}
	if len(args) != 1 || args[0] != "-g" {
		t.Fatalf("unexpected args: %v", args)
	}
}

func TestCommandOverride(t *testing.T) {
	t.Setenv("GRAVITY_COMMAND", "  /bin/echo hello world ")
	name, args := command()
	if name != "/bin/echo" {
		t.Fatalf("unexpected name: %s", name)
	}
	if len(args) != 2 || args[0] != "hello" || args[1] != "world" {
		t.Fatalf("unexpected args: %v", args)
	}
}

func TestRunError(t *testing.T) {
	if err := run("/bin/false", nil); err == nil {
		t.Fatal("expected error from /bin/false")
	}
}

func TestRunSuccess(t *testing.T) {
	if err := run("/bin/echo", []string{"ok"}); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}
