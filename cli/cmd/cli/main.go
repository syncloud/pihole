package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"go.uber.org/zap"
	"hooks/installer"
	"hooks/log"
)

func command(use string, run func(*installer.Installer) error) *cobra.Command {
	return &cobra.Command{
		Use: use,
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := log.Logger(zap.DebugLevel)
			logger.Info(use)
			return run(installer.New(logger))
		},
	}
}

func main() {
	var cmd = &cobra.Command{
		Use:          "cli",
		SilenceUsage: true,
	}

	cmd.AddCommand(command("install", func(i *installer.Installer) error { return i.Install() }))
	cmd.AddCommand(command("configure", func(i *installer.Installer) error { return i.Configure() }))
	cmd.AddCommand(command("storage-change", func(i *installer.Installer) error { return i.StorageChange() }))
	cmd.AddCommand(command("access-change", func(i *installer.Installer) error { return i.AccessChange() }))
	cmd.AddCommand(command("pre-refresh", func(i *installer.Installer) error { return i.PreRefresh() }))
	cmd.AddCommand(command("post-refresh", func(i *installer.Installer) error { return i.PostRefresh() }))
	cmd.AddCommand(command("backup-pre-stop", func(i *installer.Installer) error { return i.BackupPreStop() }))
	cmd.AddCommand(command("restore-pre-start", func(i *installer.Installer) error { return i.RestorePreStart() }))
	cmd.AddCommand(command("restore-post-start", func(i *installer.Installer) error { return i.RestorePostStart() }))

	if err := cmd.Execute(); err != nil {
		fmt.Print(err)
		os.Exit(1)
	}
}
