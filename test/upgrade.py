from subprocess import check_output

import pytest
import requests
from syncloudlib.http import wait_for_rest
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from test import snapd
from test.blocking import wait_for_blocking
from test.services import assert_no_restarts

TMP_DIR = '/tmp/syncloud'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir):
    def module_teardown():
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/refresh.journalctl.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), artifact_dir, throw=False)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, app, device_host, domain, device):
    add_host_alias(app, device_host, domain)
    device.activated()
    snapd.settle(device)


def test_upgrade(device_host, device_password, app_archive_path, app_domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 100)


def test_blocks_ads_after_upgrade(device):
    wait_for_blocking(device)


def test_services_started_cleanly(device):
    assert_no_restarts(device)
