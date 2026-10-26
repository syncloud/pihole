import os
import time
from os.path import dirname, join
from subprocess import check_output

import pytest
import requests
from syncloudlib.http import wait_for_rest
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install, wait_for_installer

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud'
FTL = '/snap/pihole/current/FTL/bin/pihole-FTL'
DIG = '/snap/pihole/current/bind9/bin/dig.sh'
GRAVITY_DB = '/var/snap/pihole/current/etc/pihole/gravity.db'
LEGACY_DB = '/var/snap/pihole/current/gravity.db'
LEGACY_ADLIST = 'https://example.com/legacy-adlist.txt'
LEGACY_DENY = 'legacy-deny.example.com'
AD_DOMAIN = 'ad.doubleclick.net'


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


@pytest.mark.flaky(retries=50, delay=10)
def test_activate_device(device):
    device.run_ssh('rm -f /var/snap/platform/current/syncloud.crt', throw=False)
    response = device.activate_custom()
    assert response.status_code == 200, response.text


def test_install(device_session, app_archive_path, device_host, app_domain, device_password, domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_installer(device_session, domain)


def test_cli_status_web(device):
    assert "-1" not in device.run_ssh('snap run pihole.cli status web')


def test_cli_admin_setdns(device):
    assert 'Failed' not in device.run_ssh('snap run pihole.cli -a setdns')


def test_cli_gravity(device):
    device.run_ssh('snap run pihole.cli -g')


def sql(device, db, query):
    return device.run_ssh('{0} sqlite3 {1} \\"{2}\\"'.format(FTL, db, query)).strip()


def test_blocks_ads(device):
    assert int(sql(device, GRAVITY_DB, 'select count(*) from adlist')) > 0
    assert int(sql(device, GRAVITY_DB, 'select count(*) from gravity')) > 0
    answer = device.run_ssh('{0} @127.0.0.1 +short {1}'.format(DIG, AD_DOMAIN))
    assert answer.strip() == '0.0.0.0', answer


def test_migrates_pre_v6_lists(device, app_archive_path, device_host, device_password):
    sql(device, LEGACY_DB,
        "create table adlist (id integer primary key autoincrement, address text unique not null,"
        " enabled boolean not null default 1, date_added integer not null default 0,"
        " date_modified integer not null default 0, comment text);"
        " create table domainlist (id integer primary key autoincrement, type integer not null default 0,"
        " domain text not null, enabled boolean not null default 1, date_added integer not null default 0,"
        " date_modified integer not null default 0, comment text, unique(domain, type));"
        " insert into adlist (address) values ('{0}');"
        " insert into domainlist (type, domain) values (1, '{1}');".format(LEGACY_ADLIST, LEGACY_DENY))
    local_install(device_host, device_password, app_archive_path)
    assert sql(device, GRAVITY_DB, "select count(*) from adlist where address = '{0}'".format(LEGACY_ADLIST)) == '1'
    assert sql(device, GRAVITY_DB, "select count(*) from domainlist where domain = '{0}'".format(LEGACY_DENY)) == '1'


def test_web_requires_auth(app_domain):
    session = requests.session()
    last = None
    for _ in range(60):
        r = session.get("https://{0}/admin/".format(app_domain), verify=False, allow_redirects=False, timeout=10)
        last = r.status_code
        if r.status_code in (301, 302, 303):
            assert 'auth.' in r.headers.get('Location', ''), r.headers.get('Location')
            return
        time.sleep(2)
    assert False, "expected redirect to Authelia portal, last status {0}".format(last)


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
