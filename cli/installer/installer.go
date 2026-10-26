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
	App             string
	AppDir          string
	DataDir         string
	CommonDir       string
	AuthUrl         string
	AuthLocalSocket string
}

type Installer struct {
	platformClient *platform.Client
	gravity        *Gravity
	leftovers      *Leftovers
	logger         *zap.Logger
}

func New(logger *zap.Logger) *Installer {
	return &Installer{
		platformClient: platform.New(),
		gravity: &Gravity{
			Ftl:            path.Join(AppDir, "FTL", "bin", "pihole-FTL"),
			Db:             path.Join(DataDir, "etc", "pihole", "gravity.db"),
			LegacyDb:       path.Join(DataDir, "gravity.db"),
			AdlistsFile:    path.Join(DataDir, "etc", "pihole", "adlists.list"),
			DefaultAdlists: path.Join(AppDir, "config", "pihole", "adlists.list"),
			Runner:         NewExecutor(logger),
		},
		leftovers: &Leftovers{
			Patterns: []string{
				path.Join(CommonDir, "pihole-FTL.db"),
				path.Join(CommonDir, "log", "pihole-FTL.log"),
				path.Join(CommonDir, "log", "pihole.log"),
				path.Join(CommonDir, "ftl.sock"),
				path.Join(CommonDir, "installed"),
				path.Join(DataDir, "gravity_old.db"),
				path.Join(DataDir, "setupVars.conf"),
				path.Join(DataDir, "config", "pihole", "dns-servers.conf"),
				path.Join(DataDir, "config", "pihole", "local.list"),
				path.Join(DataDir, "config", "pihole", "pihole-FTL.conf"),
				path.Join(DataDir, "config", "pihole", "setupVars.conf.dist"),
				path.Join(DataDir, "config", "pihole", "list.*.domains*"),
			},
			Logger: logger,
		},
		logger: logger,
	}
}

func (i *Installer) Install() error {
	return i.UpdateConfigs()
}

func (i *Installer) Configure() error {
	if err := i.StorageChange(); err != nil {
		return err
	}
	if err := i.gravity.Seed(); err != nil {
		return fmt.Errorf("seed adlists: %w", err)
	}
	if err := i.FixPermissions(); err != nil {
		return err
	}
	return i.WriteVersion()
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
	if err := i.SeedToml(); err != nil {
		return fmt.Errorf("seed toml: %w", err)
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

func (i *Installer) SeedToml() error {
	toml := path.Join(DataDir, "etc", "pihole", "pihole.toml")
	if _, err := os.Stat(toml); err == nil {
		return nil
	}
	seed, err := os.ReadFile(path.Join(DataDir, "config", "pihole.toml"))
	if err != nil {
		return err
	}
	return os.WriteFile(toml, seed, 0644)
}

func (i *Installer) PreRefresh() error {
	return nil
}

func (i *Installer) PostRefresh() error {
	if err := i.leftovers.Remove(); err != nil {
		return fmt.Errorf("remove leftovers: %w", err)
	}
	if err := i.UpdateConfigs(); err != nil {
		return err
	}
	return os.RemoveAll(path.Join(DataDir, "version"))
}

func (i *Installer) WriteVersion() error {
	version, err := os.ReadFile(path.Join(AppDir, "version"))
	if err != nil {
		return err
	}
	return os.WriteFile(path.Join(DataDir, "version"), version, 0644)
}

func (i *Installer) FixPermissions() error {
	if err := linux.Chown(DataDir, App); err != nil {
		return err
	}
	return linux.Chown(CommonDir, App)
}

func (i *Installer) BackupPreStop() error {
	return i.PreRefresh()
}

func (i *Installer) RestorePreStart() error {
	if err := i.UpdateConfigs(); err != nil {
		return err
	}
	return i.Configure()
}

func (i *Installer) RestorePostStart() error {
	return i.AccessChange()
}
