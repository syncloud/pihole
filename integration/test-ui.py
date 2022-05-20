import pytest
import time
from os.path import dirname, join

from syncloudlib.integration.hosts import add_host_alias

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode):
    def module_teardown():
        
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.run_ssh('cp /var/log/syslog {0}/syslog.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)

        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
    request.addfinalizer(module_teardown)


def test_start(module_setup, app, domain, device_host, device):
    device.activated()
    add_host_alias(app, device_host, domain)


def test_index(selenium):
    selenium.open_app()
    selenium.screenshot('index')


def test_login_good(selenium, device_user, device_password):
    _test_login(selenium, "good", device_user, device_password)


def _test_login(selenium, mode, device_user, device_password):
    selenium.find_by_xpath("//span[text()='Login']").click()
    username = selenium.find_by_xpath("//input[@name='username']")
    username.send_keys(device_user)
    password = selenium.find_by_xpath("//input[@name='pw']")
    password.send_keys(device_password)
    selenium.screenshot('login-' + mode)
    selenium.find_by_xpath("//button[contains(text(),'Log in')]").click()
    selenium.screenshot('login-submitted-' + mode)


def test_main(selenium):
    blocked_size = int(selenium.find_by_id("domains_being_blocked").text.replace(',', ''))
    selenium.screenshot('main')
    assert blocked_size > 0


def test_whitelist(selenium):
    selenium.find_by_xpath("//span[text()='Whitelist']").click()
    selenium.screenshot('whitelist')
    selenium.find_by_id("new_domain").send_keys('test.com')
    selenium.find_by_id("add2white").click()
    selenium.find_by_xpath("//code[text()='test.com']")
    selenium.screenshot('whitelist-test')


def test_blacklist_exact(selenium):
    selenium.find_by_xpath("//span[text()='Blacklist']").click()
    selenium.screenshot('blacklist')


def test_settings_networking(selenium):
    selenium.find_by_xpath("//span[text()='Settings']").click()
    selenium.screenshot('settings-networking')


def test_settings_ftl(selenium):
    cache_size = int(selenium.find_by_id("cache-size").text)
    selenium.find_by_xpath('//span[@id="status" and contains(text(), "Active")]')
    selenium.screenshot('settings-ftl')
    assert cache_size > 0


def test_local_dns(selenium, device):
    selenium.find_by_xpath("//span[text()='Local DNS']").click()
    selenium.find_by_xpath("//span[text()='DNS Records']").click()
    selenium.find_by_id("domain").send_keys('test1234.com')
    selenium.find_by_id("ip").send_keys('1.1.1.1')
    selenium.find_by_id("btnAdd").click()
    time.sleep(5)
    selenium.screenshot('local-dns')
    output = device.run_ssh('/snap/pihole/current/bind9/bin/dig.sh test1234.com @localhost')
    assert '1.1.1.1' in output

