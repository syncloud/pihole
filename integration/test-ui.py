import pytest
import time
from os.path import dirname, join
from subprocess import check_output
from selenium.webdriver.support.ui import WebDriverWait
from syncloudlib.integration.hosts import add_host_alias
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode):
    def module_teardown():
        
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)

        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
    request.addfinalizer(module_teardown)


def test_start(module_setup, app, domain, device_host, device):
    device.activated()
    add_host_alias(app, device_host, domain)


def test_index(selenium):
    selenium.open_app()
    selenium.screenshot('index')


def test_login_good(selenium, device_user, device_password, ui_mode):
    _test_login(selenium, "good", device_user, device_password, ui_mode)


def _test_login(selenium, mode, device_user, device_password, ui_mode):
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


def test_domains(selenium, ui_mode):
    selenium.find_by_xpath("//span[text()='Domains']").click()
    selenium.screenshot('domains')
    selenium.find_by_id("new_domain").send_keys('test-whitelist-{0}.com'.format(ui_mode))
    selenium.find_by_id("add2white").click()
    selenium.find_by_xpath("//code[text()='test-whitelist-{0}.com']".format(ui_mode))
    wait_for_notification(selenium)
    selenium.find_by_id("new_domain").send_keys('test-blacklist-{0}.com'.format(ui_mode))
    selenium.find_by_id("add2black").click()
    selenium.find_by_xpath("//code[text()='test-blacklist-{0}.com']".format(ui_mode))
    wait_for_notification(selenium)
    selenium.screenshot('domains-test')


def test_settings(selenium, ui_mode):
    selenium.find_by_xpath("//span[text()='Settings']").click()
    selenium.screenshot('settings')
    cache_size = int(selenium.find_by_id("cache-size").text)
    selenium.find_by_xpath('//span[@id="status" and contains(text(), "Active")]')
    selenium.screenshot('settings-ftl')
    assert cache_size > 0


def test_local_dns(selenium, device, device_host, ui_mode):
    selenium.find_by_xpath("//a[contains(.,'Local DNS')]").click()
    selenium.find_by_xpath("//a[contains(.,'DNS Records')]").click()
    selenium.find_by_id("domain").send_keys('test-local-{0}.com'.format(ui_mode))
    selenium.find_by_id("ip").send_keys('1.1.1.1')
    selenium.find_by_id("btnAdd").click()
    #time.sleep(5)
    selenium.screenshot('local-dns')
    #output = check_output('dig test-local-{0}.com @{0}'.format(device_host, ui_mode)), shell=True)
    #assert '1.1.1.1' in output


def test_adlists(selenium, device, device_host, ui_mode):
    selenium.find_by_xpath("//a[contains(.,'Adlists')]").click()
    selenium.find_by_xpath("//a[contains(.,'Update')]").click()
    

def test_teardown(driver):
    driver.quit()


def wait_for_notification(selenium):
    wait_driver = WebDriverWait(selenium.driver, 120)
    wait_driver.until(EC.invisibility_of_element_located((By.XPATH, '//span[@data-notify="message"]')))
