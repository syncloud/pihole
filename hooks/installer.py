import logging
import os
import shutil
from os.path import join, isfile
from subprocess import check_output
from syncloudlib import fs, linux, gen, logger
from syncloudlib.application import paths, storage

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
        self.app_dir = paths.get_app_dir(APP_NAME)
        self.app_data_dir = paths.get_data_dir(APP_NAME)
        self.snap_data_dir = os.environ['SNAP_DATA']

    def install_config(self):

        home_folder = join('/home', USER_NAME)
        linux.useradd(USER_NAME, home_folder=home_folder)
        
        fs.makepath(join(self.app_data_dir, 'log'))
        fs.makepath(join(self.app_data_dir, 'nginx'))
        fs.makepath(join(self.app_data_dir, 'temp'))
      
        storage.init_storage(APP_NAME, USER_NAME)

        templates_path = join(self.app_dir, 'config.templates')
        config_path = join(self.snap_data_dir, 'config')

        variables = {
            'app': APP_NAME,
            'app_dir': self.app_dir,
            'app_data_dir': self.app_data_dir,
            'snap_data': self.snap_data_dir,
            'snap_common': os.environ['SNAP_COMMON'],
            'domain': = urls.get_app_domain_name(APP_NAME),
            'ipv4': check_output(['/snap/platform/current/bin/cli', 'ipv4'])
            #'ipv6': check_output(['/snap/platform/current/bin/cli', 'ipv6'])
        }
        gen.generate_files(templates_path, config_path, variables)
        gen.generate_files(join(self.app_dir, 'etc'), join(os.environ['SNAP_COMMON'], 'etc'), variables)
        fs.chownpath(self.snap_data_dir, USER_NAME, recursive=True)
        fs.chownpath(self.app_data_dir, USER_NAME, recursive=True)
        
        #shutil.copytree(join(self.app_dir, 'etc'), join(os.environ['SNAP_COMMON'], 'etc'))

    def install(self):
        self.install_config()

    def refresh(self):
        self.install_config()
        
    def configure(self):
        self.prepare_storage()
        install_file = join(self.app_data_dir, 'installed')
        if not isfile(install_file):
            fs.touchfile(install_file)
        # else:
            # upgrade
    
    def on_disk_change(self):
        self.prepare_storage()
        
    def prepare_storage(self):
        app_storage_dir = storage.init_storage(APP_NAME, USER_NAME)
