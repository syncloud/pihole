import os
import shutil
import time
import pytest
from os.path import dirname, join, exists

from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.screenshots import screenshots
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

DIR = dirname(__file__)
screenshot_dir = join(DIR, 'screenshot')
TMP_DIR = '/tmp/syncloud/ui'

@pytest.fixture(scope="session")
def module_setup(request, device, log_dir, ui_mode):
    request.addfinalizer(lambda: module_teardown(device, log_dir, ui_mode))


def module_teardown(device, log_dir, ui_mode):
    device.activated()
    device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
    device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
    device.run_ssh('cp /var/log/syslog {0}/syslog.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
      
    device.scp_from_device('{0}/*'.format(TMP_DIR), join(log_dir, 'log'))


def test_start(module_setup, app, device_host):
    if not exists(screenshot_dir):
        os.mkdir(screenshot_dir)

    add_host_alias(app, device_host)

def test_index(driver, app_domain, ui_mode):
    url = "https://{0}".format(app_domain)
    driver.get(url)
    time.sleep(5)
    
    screenshots(driver, screenshot_dir, 'index-' + ui_mode)


def test_login_wrong(driver, app_domain, ui_mode, device_user):
    _test_login(driver, app_domain, "wrong-" + ui_mode, device_user, "wrong")


def test_login_good(driver, app_domain, ui_mode, device_user, device_password):
    _test_login(driver, app_domain, "good-" + ui_mode, device_user, device_password)


def _test_login(driver, app_domain, ui_mode, device_user, device_password):
    url = "https://{0}/login".format(app_domain)
    driver.get(url)
    time.sleep(5)
    screenshots(driver, screenshot_dir, 'login-' + ui_mode)
   
    username = driver.find_element_by_xpath("//input[@name='username']")
    username.send_keys(device_user)
    password = driver.find_element_by_xpath("//input[@name='password']")
    password.send_keys(device_password)
    screenshots(driver, screenshot_dir, 'login-1-' + ui_mode)

    password.submit()
    time.sleep(5)

    screenshots(driver, screenshot_dir, 'login-2-' + ui_mode)


def test_blacklist_exact(driver, app_domain, ui_mode):
    url = "https://{0}/blacklist/exact".format(app_domain)
    driver.get(url)
    time.sleep(5)
    
    screenshots(driver, screenshot_dir, 'blacklist-' + ui_mode)

def test_settings_networking(driver, app_domain, ui_mode):
    url = "https://{0}/settings/networking".format(app_domain)
    driver.get(url)
    time.sleep(5)
    
    screenshots(driver, screenshot_dir, 'settings-networking-' + ui_mode)


def test_settings_ftl(driver, app_domain, ui_mode):
    url = "https://{0}/settings/networking".format(app_domain)
    driver.get(url)
    time.sleep(5)
    driver.find_element_by_xpath("//a[contains(text(),'FTL')]").click()
    time.sleep(2)
    screenshots(driver, screenshot_dir, 'settings-ftl-' + ui_mode)

