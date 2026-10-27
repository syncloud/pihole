local name = "pihole";
local platform = '26.10.02';
local nginx = '1.24.0';
local store_publisher = 'stable-346';
local distro_default = 'buster';
local distros = ['bookworm', 'buster'];

local playwright = '1.59.1';

local platform_image(distro) =
    "syncloud/platform-" + distro + ":" + platform;

local snapd_hold = "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init";

local build(arch, test_ui) = [{
    kind: "pipeline",
    name: arch,

    platform: {
        os: "linux",
        arch: arch
    },
    steps: [
        {
            name: "web",
            image: "debian:bookworm-slim",
            commands: [ "./web/build.sh" ]
        },
        {
            name: "core",
            image: "debian:bookworm-slim",
            commands: [ "./core/build.sh" ]
        },
        {
            name: "ftl",
            image: "debian:bookworm-slim",
            commands: [ "./ftl/build.sh" ]
        },
    ] + [
        {
            name: "ftl test " + distro,
            image: platform_image(distro),
            commands: [ "./ftl/test.sh" ],
        }
        for distro in distros
    ] + [
        {
            name: "bind9",
            image: "debian:bookworm-slim",
            commands: [ "./bind9/build.sh" ]
        },
    ] + [
        {
            name: "bind9 test " + distro,
            image: platform_image(distro),
            commands: [ "./bind9/test.sh" ],
        }
        for distro in distros
    ] + [
        {
            name: "cli",
            image: "golang:1.22",
            commands: [ "./cli/build.sh" ]
        },
    ] + [
        {
            name: "cli test " + distro,
            image: platform_image(distro),
            commands: [ "./cli/test.sh" ],
        }
        for distro in distros
    ] + [
        {
            name: "nginx",
            image: "nginx:" + nginx,
            commands: [ "./nginx/build.sh" ]
        },
    ] + [
        {
            name: "nginx test " + distro,
            image: platform_image(distro),
            commands: [ "./nginx/test.sh" ],
        }
        for distro in distros
    ] + [
        {
            name: "package",
            image: "debian:bookworm-slim",
            commands: [ "./package.sh " + name + " $DRONE_BUILD_NUMBER" ]
        },
    ] + [
        {
            name: "test " + distro,
            image: "python:3.11-slim-bookworm",
            commands: [ "./ci/test.sh test.py " + distro + " " + arch ],
        }
        for distro in distros
    ] + ( if test_ui then [
        {
            name: 'e2e',
            image: 'mcr.microsoft.com/playwright:v' + playwright + '-jammy',
            commands: [ './test/e2e/run.sh specs/01-smoke.spec.ts' ],
        },
    ] else []) + [
        {
            name: "test-upgrade-prev",
            image: "python:3.11-slim-bookworm",
            commands: [ "./ci/test.sh upgrade_prev.py " + distro_default + " " + arch ],
        },
    ] + ( if test_ui then [
        {
            name: 'e2e-before-upgrade',
            image: 'mcr.microsoft.com/playwright:v' + playwright + '-jammy',
            commands: [ './test/e2e/run.sh specs/02-pre-upgrade.spec.ts' ],
        },
    ] else []) + [
        {
            name: "test-upgrade",
            image: "python:3.11-slim-bookworm",
            commands: [ "./ci/test.sh upgrade.py " + distro_default + " " + arch ],
        },
    ] + ( if test_ui then [
        {
            name: 'e2e-after-upgrade',
            image: 'mcr.microsoft.com/playwright:v' + playwright + '-jammy',
            commands: [ './test/e2e/run.sh specs/03-post-upgrade.spec.ts' ],
        },
    ] else []) + [
        {
            name: 'publish',
            image: 'syncloud/store-publisher:' + store_publisher,
            environment: {
                SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
            },
            command: ['snap', '-c', '${DRONE_BRANCH}'],
            when: {
                branch: ['stable'],
                event: ['push'],
            },
        },
        {
            name: "artifact",
            image: "appleboy/drone-scp:1.6.4",
            settings: {
                host: {
                    from_secret: "artifact_host"
                },
                username: "artifact",
                key: {
                    from_secret: "artifact_key"
                },
                timeout: "2m",
                command_timeout: "2m",
                target: "/home/artifact/repo/" + name + "/${DRONE_BUILD_NUMBER}-" + arch,
                source: [
                    "artifact/*"
                ],
                strip_components: 1,
            },
            when: {
                status: [ "failure", "success" ],
                event: ['push'],
            }
        }
    ],
    trigger: {
        event: [
            "push"
        ]
    },
    services: [
        {
            name: name + "." + distro + ".com",
            image: platform_image(distro),
            privileged: true,
            entrypoint: ['/bin/sh', '-c', snapd_hold],
            volumes: [
                {
                    name: "dbus",
                    path: "/var/run/dbus"
                },
                {
                    name: "dev",
                    path: "/dev"
                }
            ]
        }
        for distro in distros
    ],
    volumes: [
        {
            name: "dbus",
            host: {
                path: "/var/run/dbus"
            }
        },
        {
            name: "dev",
            host: {
                path: "/dev"
            }
        },
        {
            name: "shm",
            temp: {}
        },
    ]
}];

build("amd64", true) +
build("arm64", false) +
build("arm", false)
