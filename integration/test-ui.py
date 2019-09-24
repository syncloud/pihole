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
    time.sleep(10)
    
    screenshots(driver, screenshot_dir, 'index-' + ui_mode)


def test_login(driver, app_domain, ui_mode):
    url = "https://{0}/login".format(app_domain)
    driver.get(url)
    time.sleep(10)
    screenshots(driver, screenshot_dir, 'login-' + ui_mode)
    password = driver.find_element_by_name("password")
    password.send_keys("123")
    screenshots(driver, screenshot_dir, 'login-1-' + ui_mode)

    password.submit()
    time.sleep(5)

    screenshots(driver, screenshot_dir, 'login-2-' + ui_mode)

