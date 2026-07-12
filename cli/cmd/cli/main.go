package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"go.uber.org/zap"
	"hooks/installer"
	"hooks/log"
)

func main() {
	var cmd = &cobra.Command{
		Use:          "cli",
		SilenceUsage: true,
	}

	cmd.AddCommand(&cobra.Command{
		Use: "cron",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := log.Logger(zap.DebugLevel)
			return installer.GravityLoop(logger)
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "storage-change",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := log.Logger(zap.DebugLevel)
			logger.Info("storage-change")
			return installer.New(logger).StorageChange()
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "access-change",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := log.Logger(zap.DebugLevel)
			logger.Info("access-change")
			return installer.New(logger).AccessChange()
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "backup-pre-stop",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := log.Logger(zap.DebugLevel)
			logger.Info("backup-pre-stop")
			return installer.New(logger).BackupPreStop()
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "restore-pre-start",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := log.Logger(zap.DebugLevel)
			logger.Info("restore-pre-start")
			return installer.New(logger).RestorePreStart()
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "restore-post-start",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger := log.Logger(zap.DebugLevel)
			logger.Info("restore-post-start")
			return installer.New(logger).RestorePostStart()
		},
	})

	if err := cmd.Execute(); err != nil {
		fmt.Print(err)
		os.Exit(1)
	}
}
