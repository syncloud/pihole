SERVICES = ['ftl', 'nginx', 'gravity']


def assert_no_restarts(device):
    for service in SERVICES:
        restarts = device.run_ssh('systemctl show -p NRestarts --value snap.pihole.{0}.service'.format(service)).strip()
        assert restarts == '0', 'snap.pihole.{0} restarted {1} times'.format(service, restarts)
