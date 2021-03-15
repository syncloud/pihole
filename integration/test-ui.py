import pytest
from os.path import dirname, join

from syncloudlib.integration.hosts import add_host_alias

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode):
    def module_teardown():
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.run_ssh('cp /var/log/syslog {0}/syslog.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)

        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
    request.addfinalizer(module_teardown)


def test_start(module_setup, app, device_host):
    add_host_alias(app, device_host)


def test_index(selenium):
    selenium.open_app()
    selenium.screenshot('index')


#def test_login_wrong(selenium):
#    _test_login(selenium, "wrong", "wrong", "wrong")


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


def test_whitelist(selenium):
    selenium.find_by_xpath("//span[text()='Whitelist']").click()
    selenium.screenshot('whitelist')
    selenium.find_by_id("new_domain").send_keys('test.com')
    selenium.find_by_id("add2white").click()
    selenium.find_by_xpath("//span[text()='test.com']")


def test_blacklist_exact(selenium):
    selenium.find_by_xpath("//span[text()='Blacklist']").click()
    selenium.screenshot('blacklist')


def test_settings_networking(selenium):
    selenium.find_by_xpath("//span[text()='Settings']").click()
    selenium.screenshot('settings-networking')


def test_settings_ftl(selenium):
    cache_size = int(selenium.find_by_id("cache-size").text)
    selenium.screenshot('settings-ftl')
    assert cache_size > 0

