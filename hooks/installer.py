import logging
import os
import shutil
from os.path import join, isfile
from subprocess import check_output, CalledProcessError

from syncloudlib import fs, linux, gen, logger
from syncloudlib.application import paths, storage, urls

APP_NAME = 'pihole'

USER_NAME = 'pihole'
DB_NAME = APP_NAME
DB_USER = APP_NAME
DB_PASSWORD = APP_NAME


class Installer:
    def __init__(self):
        if not logger.factory_instance:
            logger.init(logging.DEBUG, True)

        self.log = logger.get_logger('{0}_installer'.format(APP_NAME))
        self.snap = paths.get_app_dir(APP_NAME)
        self.snap_common = paths.get_data_dir(APP_NAME)
        self.snap_data = os.environ['SNAP_DATA']
        self.config_path = join(self.snap_data, 'config')

    def install_config(self):

        home_folder = join('/home', USER_NAME)
        linux.useradd(USER_NAME, home_folder=home_folder)
        
        fs.makepath(join(self.snap_common, 'log'))
        fs.makepath(join(self.snap_data, 'nginx'))
        fs.makepath(join(self.snap_data, 'temp'))
        fs.makepath(join(self.snap_data, 'run'))
        fs.makepath(join(self.snap_data, 'misc'))
        storage.init_storage(APP_NAME, USER_NAME)

        templates_path = join(self.snap, 'config')

        variables = {
            'app': APP_NAME,
            'app_dir': self.snap,
            'snap_data': self.snap_data,
            'snap_common': self.snap_common,
            'domain': urls.get_app_domain_name(APP_NAME),
            'ipv4': check_output(['snap', 'run', 'platform.cli', 'ipv4'])
            #'ipv6': check_output(['/snap/platform/current/bin/cli', 'ipv6'])
        }
        gen.generate_files(templates_path, self.config_path, variables)
        fs.chownpath(self.snap_data, USER_NAME, recursive=True)
        fs.chownpath(self.snap_common, USER_NAME, recursive=True)

    def install(self):
        self.install_config()
        config_file = join(self.snap_data, 'setupVars.conf')
        config_file_dist = join(self.config_path, 'pihole/setupVars.conf.dist')
        if not isfile(config_file): 
            shutil.copy(config_file_dist, config_file)
        self.run_gravity()

    def refresh(self):
        self.install()

    def run_gravity(self):
        try:
            gravity_log = check_output(['snap', 'run', 'pihole.cli', '-g'])
            with open(join(self.snap_common, 'log', 'pihole.log'), 'w') as f:
                f.write(str(gravity_log))
        except CalledProcessError as e:
            print(e.output)
            raise e

    def configure(self):
        self.prepare_storage()
        install_file = join(self.snap_common, 'installed')
        if not isfile(install_file):
            fs.touchfile(install_file)
        # else:
            # upgrade
    
    def on_disk_change(self):
        self.prepare_storage()
        
    def prepare_storage(self):
        storage.init_storage(APP_NAME, USER_NAME)

