package installer

import (
	"fmt"
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
	App             string
	AppDir          string
	DataDir         string
	CommonDir       string
	AuthUrl         string
	AuthLocalSocket string
}

type Installer struct {
	platformClient *platform.Client
	logger         *zap.Logger
}

func New(logger *zap.Logger) *Installer {
	return &Installer{
		platformClient: platform.New(),
		logger:         logger,
	}
}

func (i *Installer) Install() error {
	return i.UpdateConfigs()
}

func (i *Installer) Configure() error {
	return i.StorageChange()
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
	); err != nil {
		return err
	}
	if err := i.GenerateConfig(); err != nil {
		return fmt.Errorf("generate config: %w", err)
	}
	return i.FixPermissions()
}

func (i *Installer) GenerateConfig() error {
	authUrl, err := i.platformClient.GetAppUrl("auth")
	if err != nil {
		return err
	}
	variables := Variables{
		App:             App,
		AppDir:          AppDir,
		DataDir:         DataDir,
		CommonDir:       CommonDir,
		AuthUrl:         authUrl,
		AuthLocalSocket: i.platformClient.GetAuthLocalSocket(),
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
	return i.UpdateConfigs()
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
