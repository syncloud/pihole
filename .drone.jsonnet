local name = "pihole";
local platform = '26.04.10';
local nginx = '1.24.0';
local store_publisher = 'stable-303';


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
        {
            name: "bind9",
            image: "debian:bullseye-slim",
            commands: [ "./bind9/build.sh" ]
        },
        {
            name: "build cli",
            image: "golang:1.22",
            commands: [ "./cli/build.sh" ]
        },
        {
            name: "nginx",
            image: "nginx:" + nginx,
            commands: [ "./nginx/build.sh" ]
        },
    {
        name: "build",
        image: "debian:bookworm-slim",
        commands: [
            "./build.sh"
        ],
    },

            {
        name: "package",
        image: "debian:bookworm-slim",
        commands: [
            "./package.sh " + name + " $DRONE_BUILD_NUMBER"
        ]
    },
        {
      name: 'test',
      image: 'python:3.11-slim-bookworm',
      commands: [
        './test/ci-test.sh buster ' + arch,
      ],
    },
] + ( if test_ui then [
         {
           name: 'e2e',
           image: 'mcr.microsoft.com/playwright:v1.48.2-jammy',
           commands: [
             './test/e2e/run.sh e2e specs/01-smoke.spec.ts desktop',
           ],
         },
       ] else []) + [

    {
        name: "test-upgrade",
        image: "python:3.11-slim-bookworm",
        commands: [
          "./test/ci-upgrade.sh buster " + arch,
        ],
        privileged: true,
        volumes: [{
            name: "videos",
            path: "/videos"
        }]
    },
    {
      name: 'publish',
      image: 'syncloud/store-publisher:' + store_publisher,
      environment: {
        SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
      },
      command: ['snap', '-c', '${DRONE_BRANCH}'],
      when: {
        branch: ['master', 'stable'],
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
            privileged: true,
            strip_components: 1,
            volumes: [
               {
                    name: "videos",
                    path: "/drone/src/artifact/videos"
                }
            ]
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
            name: name + ".buster.com",
            image: "syncloud/platform-buster-" + arch + ":" + platform,
            privileged: true,
            entrypoint: ['/bin/sh', '-c', "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init"],
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
        {
            name: "videos",
            temp: {}
        },
    ]
}];

build("amd64", true) +
build("arm64", false) +
build("arm", false)
