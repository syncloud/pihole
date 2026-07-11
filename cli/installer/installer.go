package installer

import (
	"fmt"
	"os"
	"path"

	"github.com/syncloud/golib/config"
	"github.com/syncloud/golib/linux"
	"github.com/syncloud/golib/platform"
	"go.uber.org/zap"
)

const (
	App       = "pihole"
	AppDir    = "/snap/pihole/current"
	DataDir   = "/var/snap/pihole/current"
	CommonDir = "/var/snap/pihole/common"
)

type Variables struct {
	App       string
	AppDir    string
	DataDir   string
	CommonDir string
}

type Installer struct {
	newVersionFile     string
	currentVersionFile string
	platformClient     *platform.Client
	logger             *zap.Logger
}

func New(logger *zap.Logger) *Installer {
	return &Installer{
		newVersionFile:     path.Join(AppDir, "version"),
		currentVersionFile: path.Join(DataDir, "version"),
		platformClient:     platform.New(),
		logger:             logger,
	}
}

func (i *Installer) StorageChange() error {
	storageDir, err := i.platformClient.InitStorage(App, App)
	if err != nil {
		return err
	}
	return linux.Chown(storageDir, App)
}

func (i *Installer) AccessChange() error {
	return i.UpdateConfigs()
}

func (i *Installer) UpdateConfigs() error {
	if err := linux.CreateUser(App); err != nil {
		return err
	}
	if err := linux.CreateMissingDirs(
		path.Join(DataDir, "config"),
		path.Join(DataDir, "nginx"),
		path.Join(DataDir, "etc", "pihole"),
		path.Join(CommonDir, "log", "pihole"),
	); err != nil {
		return err
	}
	if err := i.GenerateConfig(); err != nil {
		return fmt.Errorf("generate config: %w", err)
	}
	return i.FixPermissions()
}

func (i *Installer) GenerateConfig() error {
	variables := Variables{
		App:       App,
		AppDir:    AppDir,
		DataDir:   DataDir,
		CommonDir: CommonDir,
	}
	return config.Generate(
		path.Join(AppDir, "config"),
		path.Join(DataDir, "config"),
		variables,
	)
}

func (i *Installer) PreRefresh() error {
	return nil
}

func (i *Installer) PostRefresh() error {
	if err := i.UpdateConfigs(); err != nil {
		return err
	}
	return i.ClearVersion()
}

func (i *Installer) ClearVersion() error {
	return os.RemoveAll(i.currentVersionFile)
}

func (i *Installer) FixPermissions() error {
	if err := linux.Chown(DataDir, App); err != nil {
		return err
	}
	return linux.Chown(CommonDir, App)
}

func (i *Installer) BackupPreStop() error    { return i.PreRefresh() }
func (i *Installer) RestorePreStart() error  { return i.PostRefresh() }
func (i *Installer) RestorePostStart() error { return i.AccessChange() }
