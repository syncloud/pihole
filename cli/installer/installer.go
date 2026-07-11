package installer

import (
	"fmt"
	"os"
	"path"
	"strings"

	"github.com/syncloud/golib/config"
	"github.com/syncloud/golib/linux"
	"github.com/syncloud/golib/platform"
	"go.uber.org/zap"
)

const App = "pihole"

type Variables struct {
	App       string
	AppDir    string
	DataDir   string
	CommonDir string
	AppUrl    string
	AppDomain string
	Domain    string
}

type Installer struct {
	newVersionFile     string
	currentVersionFile string
	platformClient     *platform.Client
	installFile        string
	appDir             string
	dataDir            string
	commonDir          string
	executor           *Executor
	logger             *zap.Logger
}

func New(logger *zap.Logger) *Installer {
	appDir := fmt.Sprintf("/snap/%s/current", App)
	dataDir := fmt.Sprintf("/var/snap/%s/current", App)
	commonDir := fmt.Sprintf("/var/snap/%s/common", App)

	return &Installer{
		newVersionFile:     path.Join(appDir, "version"),
		currentVersionFile: path.Join(dataDir, "version"),
		platformClient:     platform.New(),
		installFile:        path.Join(dataDir, "installed"),
		appDir:             appDir,
		dataDir:            dataDir,
		commonDir:          commonDir,
		executor:           NewExecutor(logger),
		logger:             logger,
	}
}

func (i *Installer) Install() error {
	err := linux.CreateUser(App)
	if err != nil {
		return err
	}

	err = i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.StorageChange()
	if err != nil {
		return err
	}

	return i.FixPermissions()
}

func (i *Installer) Configure() error {
	if i.IsInstalled() {
		err := i.Upgrade()
		if err != nil {
			return err
		}
	} else {
		err := i.Initialize()
		if err != nil {
			return err
		}
	}

	err := i.FixPermissions()
	if err != nil {
		return err
	}

	i.RunGravity()

	return i.UpdateVersion()
}

func (i *Installer) Initialize() error {
	err := i.StorageChange()
	if err != nil {
		return err
	}
	return os.WriteFile(i.installFile, []byte("installed"), 0644)
}

func (i *Installer) Upgrade() error {
	return i.StorageChange()
}

func (i *Installer) IsInstalled() bool {
	_, err := os.Stat(i.installFile)
	return err == nil
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
	err := linux.CreateMissingDirs(
		path.Join(i.dataDir, "nginx"),
		path.Join(i.dataDir, "etc", "pihole"),
		path.Join(i.commonDir, "log", "pihole"),
	)
	if err != nil {
		return err
	}

	appUrl, err := i.platformClient.GetAppUrl(App)
	if err != nil {
		return err
	}

	appDomain, err := i.platformClient.GetAppDomainName(App)
	if err != nil {
		return err
	}

	domain, found := strings.CutPrefix(appDomain, App)
	if !found {
		return fmt.Errorf("%s is not in %s", App, appDomain)
	}

	variables := Variables{
		App:       App,
		AppDir:    i.appDir,
		DataDir:   i.dataDir,
		CommonDir: i.commonDir,
		AppUrl:    appUrl,
		AppDomain: appDomain,
		Domain:    domain,
	}

	return config.Generate(
		path.Join(i.appDir, "config"),
		path.Join(i.dataDir, "config"),
		variables,
	)
}

func (i *Installer) RunGravity() {
	out, err := i.executor.Run("snap", "run", "pihole.cli", "-g")
	if err != nil {
		i.logger.Warn("gravity update failed", zap.String("output", out), zap.Error(err))
	}
}

func (i *Installer) PreRefresh() error {
	return nil
}

func (i *Installer) PostRefresh() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}
	return i.FixPermissions()
}

func (i *Installer) BackupPreStop() error {
	return i.PreRefresh()
}

func (i *Installer) RestorePreStart() error {
	return i.PostRefresh()
}

func (i *Installer) RestorePostStart() error {
	return i.Configure()
}

func (i *Installer) UpdateVersion() error {
	content, err := os.ReadFile(i.newVersionFile)
	if err != nil {
		return err
	}
	return os.WriteFile(i.currentVersionFile, content, 0644)
}

func (i *Installer) FixPermissions() error {
	err := linux.Chown(i.dataDir, App)
	if err != nil {
		return err
	}
	return linux.Chown(i.commonDir, App)
}
