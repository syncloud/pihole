import time

SERVICES = ['ftl', 'nginx', 'gravity']


def assert_no_restarts(device):
    for service in SERVICES:
        unit = 'snap.pihole.{0}.service'.format(service)
        journal = device.run_ssh('journalctl -u {0} -o cat'.format(unit))
        exited = ''
        for line in journal.splitlines():
            if 'Main process exited' in line:
                exited = line
            elif 'Scheduled restart job' in line:
                assert 'status=22/' in exited, '{0} restarted after: {1}'.format(unit, exited or line)
                exited = ''


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
