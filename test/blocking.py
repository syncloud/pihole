import time

FTL = '/snap/pihole/current/FTL/bin/pihole-FTL'
DIG = '/snap/pihole/current/bind9/bin/dig.sh'
GRAVITY_DB = '/var/snap/pihole/current/etc/pihole/gravity.db'
AD_DOMAIN = 'ad.doubleclick.net'


def sql(device, db, query):
    return device.run_ssh('{0} sqlite3 -cmd \\".timeout 30000\\" {1} \\"{2}\\"'.format(FTL, db, query)).strip()


def wait_for_blocking(device):
    answer = ''
    for _ in range(60):
        answer = device.run_ssh('{0} @127.0.0.1 +short {1}'.format(DIG, AD_DOMAIN), throw=False).strip()
        if answer == '0.0.0.0':
            return
        time.sleep(5)
    assert False, 'gravity: {0} adlists, {1} domains, {2} resolves to {3}'.format(
        sql(device, GRAVITY_DB, 'select count(*) from adlist'),
        sql(device, GRAVITY_DB, 'select count(*) from gravity'), AD_DOMAIN, answer)
