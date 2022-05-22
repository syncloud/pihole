import os
import shutil
import json
from os.path import dirname, join
from subprocess import check_output

import pytest
import requests
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install, wait_for_installer
from syncloudlib.http import wait_for_rest

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud'


@pytest.fixture(scope="session")
def module_setup(request, device, data_dir, platform_data_dir, app_dir, artifact_dir):
    def module_teardown():
        platform_log_dir = join(artifact_dir, 'platform_log')
        os.mkdir(platform_log_dir)
        device.scp_from_device('{0}/log/*'.format(platform_data_dir), platform_log_dir)

        device.run_ssh('mkdir {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('top -bn 1 -w 500 -c > {0}/top.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ps auxfw > {0}/ps.log'.format(TMP_DIR), throw=False)
        device.run_ssh('netstat -nlp > {0}/netstat.log'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/log/syslog {0}/syslog.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/log/messages {0}/messages.log'.format(TMP_DIR), throw=False)
        device.run_ssh('cp /var/snap/pihole/current/setupVars.conf {0}/setupVars.conf.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /snap/pihole/current/ > {0}/snap.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/ > {1}/app.ls.log'.format(app_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/ > {1}/data.ls.log'.format(data_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/pihole/current/config/pihole > {0}/snap.data.config.pihole.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/pihole/current/config > {0}/snap.data.config.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/pihole/current > {0}/snap.data.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la /var/snap/pihole/common > {0}/snap.common.ls.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/web > {1}/web.ls.log'.format(app_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/log > {1}/log.ls.log'.format(data_dir, TMP_DIR), throw=False)
        #device.run_ssh('rm {0}/etc/pihole/gravity.db'.format(data_dir), throw=False)
        #device.run_ssh('{0}/bin/gravity.sh > {1}/gravity.log 2>&1'.format(app_dir, TMP_DIR), throw=False)
        #device.run_ssh('ls -la {0}/etc/pihole > {1}/data.etc.pihole.1.ls.log'.format(data_dir, TMP_DIR), throw=False)
        app_log_dir = join(artifact_dir, 'log')
        os.mkdir(app_log_dir)
        device.scp_from_device('{0}/log/*.log'.format(data_dir), app_log_dir)
        device.scp_from_device('{0}/*'.format(TMP_DIR), app_log_dir)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, device, device_host, app, domain):
    add_host_alias(app, device_host, domain)
    device.run_ssh('date', retries=100)
    device.run_ssh('mkdir {0}'.format(TMP_DIR))


def test_activate_device(device):
    response = device.activate_custom()
    assert response.status_code == 200, response.text


def test_install(device_session, app_archive_path, device_host, app_domain, device_password):
    local_install(device_host, device_password, app_archive_path)


def test_cli_status_web(device):
    assert "-1" not in device.run_ssh('snap run pihole.cli status web')


def test_cli_admin_setdns(device):
    assert 'Failed' not in device.run_ssh('snap run pihole.cli -a setdns')


#def test_api(app_domain):
#    response = requests.get('https://{0}/api/stats/summary'.format(app_domain), verify=False)
#    assert response.status_code == 200, response.text


#def test_auth_mode(app_domain):
#    response = requests.get('https://{0}/api/auth/mode'.format(app_domain), verify=False)
#    assert response.status_code == 200, response.text
#    assert json.loads(response.text)["mode"] == "ldap"


# def test_upgrade(app_archive_path, device_host, device_password):
#     local_install(device_host, device_password, app_archive_path)


def test_remove(device, app):
    response = device.app_remove(app)
    assert response.status_code == 200, response.text


def test_reinstall(app_archive_path, device_host, device_password):
    local_install(device_host, device_password, app_archive_path)
