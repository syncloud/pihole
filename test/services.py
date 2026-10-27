import time

SERVICES = ['ftl', 'nginx', 'gravity']


def assert_no_restarts(device):
    for service in SERVICES:
        restarts = device.run_ssh('systemctl show -p NRestarts --value snap.pihole.{0}.service'.format(service)).strip()
        assert restarts == '0', 'snap.pihole.{0} restarted {1} times'.format(service, restarts)


def main_pid(device, service):
    return device.run_ssh('systemctl show -p MainPID --value snap.pihole.{0}.service'.format(service)).strip()


def wait_for_new_main_pid(device, service, old_pid):
    pid = old_pid
    for _ in range(60):
        pid = main_pid(device, service)
        if pid not in ('0', old_pid):
            return
        time.sleep(1)
    assert False, 'snap.pihole.{0} still has MainPID {1}'.format(service, pid)
