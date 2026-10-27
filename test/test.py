import os
import time
from concurrent.futures import ThreadPoolExecutor
from os.path import join
from subprocess import check_output

import pytest
import requests
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install, wait_for_installer
from test import snapd
from test.blocking import GRAVITY_DB, sql, wait_for_blocking
from test.services import assert_no_restarts

TMP_DIR = '/tmp/syncloud'
DATA_DIR = '/var/snap/pihole/current'
COMMON_DIR = '/var/snap/pihole/common'
LEGACY_DB = DATA_DIR + '/gravity.db'
LEGACY_ADLIST = 'https://example.com/legacy-adlist.txt'
LEGACY_DENY = 'legacy-deny.example.com'
HOST_LISTS_CACHE = '/etc/pihole/listsCache'
LEFTOVERS = [
    COMMON_DIR + '/pihole-FTL.db',
    COMMON_DIR + '/log/pihole-FTL.log',
    COMMON_DIR + '/installed',
    DATA_DIR + '/gravity_old.db',
    DATA_DIR + '/setupVars.conf',
    DATA_DIR + '/config/pihole/list.1.raw.githubusercontent.com.domains',
]


@pytest.fixture(scope="session")
def module_setup(request, device, platform_data_dir, app_dir, artifact_dir):
    def module_teardown():
        platform_log_dir = join(artifact_dir, 'platform_log')
        os.mkdir(platform_log_dir)
        device.scp_from_device('{0}/log/*'.format(platform_data_dir), platform_log_dir)

        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('top -bn 1 -w 500 -c > {0}/top.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ps auxfw > {0}/ps.log'.format(TMP_DIR), throw=False)
        device.run_ssh('netstat -nlp > {0}/netstat.log'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.log'.format(TMP_DIR), throw=False)
        device.run_ssh('ls -la {0}/ > {1}/app.ls.log'.format(app_dir, TMP_DIR), throw=False)
        device.run_ssh('ls -laR {0}/ > {1}/data.ls.log'.format(DATA_DIR, TMP_DIR), throw=False)
        device.run_ssh('ls -laR {0}/ > {1}/common.ls.log'.format(COMMON_DIR, TMP_DIR), throw=False)
        app_log_dir = join(artifact_dir, 'log')
        os.mkdir(app_log_dir)
        device.scp_from_device('{0}/*'.format(TMP_DIR), app_log_dir)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, device, device_host, app, domain):
    add_host_alias(app, device_host, domain)
    device.run_ssh('date', retries=100)
    snapd.settle(device)
    device.run_ssh('mkdir -p {0}'.format(TMP_DIR))


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


def test_blocks_ads(device):
    wait_for_blocking(device)


def test_services_started_cleanly(device):
    assert_no_restarts(device)


def test_cli_gravity(device):
    device.run_ssh('snap run pihole.cli -g')


def test_cli_gravity_concurrent(device):
    with ThreadPoolExecutor(max_workers=2) as pool:
        runs = [pool.submit(device.run_ssh, 'snap run pihole.cli -g') for _ in range(2)]
        for run in runs:
            run.result()


def test_refresh_migrates_pre_v6_data(device, app_archive_path, device_host, device_password):
    sql(device, LEGACY_DB,
        "create table adlist (id integer primary key autoincrement, address text unique not null,"
        " enabled boolean not null default 1, date_added integer not null default 0,"
        " date_modified integer not null default 0, comment text);"
        " create table domainlist (id integer primary key autoincrement, type integer not null default 0,"
        " domain text not null, enabled boolean not null default 1, date_added integer not null default 0,"
        " date_modified integer not null default 0, comment text, unique(domain, type));"
        " insert into adlist (address) values ('{0}');"
        " insert into domainlist (type, domain) values (1, '{1}');".format(LEGACY_ADLIST, LEGACY_DENY))
    device.run_ssh('mkdir -p {0}/log {1}'.format(COMMON_DIR, HOST_LISTS_CACHE))
    for leftover in LEFTOVERS:
        device.run_ssh('touch {0}'.format(leftover))
    local_install(device_host, device_password, app_archive_path)
    assert sql(device, GRAVITY_DB, "select count(*) from adlist where address = '{0}'".format(LEGACY_ADLIST)) == '1'
    assert sql(device, GRAVITY_DB, "select count(*) from domainlist where domain = '{0}'".format(LEGACY_DENY)) == '1'
    remaining = device.run_ssh('ls -d {0} {1} {2} 2>/dev/null'.format(LEGACY_DB, HOST_LISTS_CACHE, ' '.join(LEFTOVERS)), throw=False)
    assert remaining.strip() == '', remaining
    wait_for_blocking(device)
    assert_no_restarts(device)


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


def test_remove(device, app):
    response = device.app_remove(app)
    assert response.status_code == 200, response.text


def test_reinstall(app_archive_path, device_host, device_password, device):
    local_install(device_host, device_password, app_archive_path)
    wait_for_blocking(device)
    assert_no_restarts(device)
