local name = "pihole";
local platform = '26.04.10';
local nginx = '1.24.0';
local deployer = 'https://github.com/syncloud/store/releases/download/4/syncloud-release';


local build(arch, test_ui, dind) = [{
    kind: "pipeline",
    name: arch,

    platform: {
        os: "linux",
        arch: arch
    },
    steps: [
        {
            name: "version",
            image: "debian:bookworm-slim",
            commands: [
                "echo $DRONE_BUILD_NUMBER > version"
            ]
        },
        {
            name: "download",
            image: "debian:bookworm-slim",
            commands: [
                "./download.sh"
            ]
        },
        {
            name: "build gravity",
            image: "golang:1.22",
            commands: [
                "./gravity/build.sh"
            ]
        },
        {
            name: "build cli",
            image: "golang:1.22",
            commands: [
                "./cli/build.sh"
            ]
        },
        {
            name: "nginx",
            image: "nginx:" + nginx,
            commands: [
                "./nginx/build.sh"
            ]
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
            "VERSION=$(cat version)",
            "./package.sh " + name + " $VERSION "
        ]
    },
        {
      name: 'test',
      image: 'python:3.11-slim-bookworm',
      commands: [
        'APP_ARCHIVE_PATH=$(realpath $(cat package.name))',
        'cd test',
        './deps.sh',
        "getent hosts " + name + ".buster.com | sed 's/" + name +".buster.com/auth.buster.com/g' | tee -a /etc/hosts",  
        'py.test -x -s test.py --distro=buster --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=' + name + '.buster.com --app=' + name + ' --arch=' + arch,
      ],
    },
] + ( if test_ui then [
         {
           name: 'e2e',
           image: 'mcr.microsoft.com/playwright:v1.48.2-jammy',
           environment: {
             PLAYWRIGHT_FULL_DOMAIN: 'buster.com',
             PLAYWRIGHT_APP_DOMAIN: name + '.buster.com',
             PLAYWRIGHT_DEVICE_HOST: name + '.buster.com',
             PLAYWRIGHT_DEVICE_USER: 'user',
             PLAYWRIGHT_DEVICE_PASSWORD: 'Password1',
             PLAYWRIGHT_ARTIFACT_DIR: '/drone/src/artifact/e2e',
           },
           commands: [
             'apt-get update -qq && apt-get install -y -qq sshpass openssh-client curl',
             "getent hosts " + name + ".buster.com | sed 's/" + name + ".buster.com/auth.buster.com/g' | tee -a /etc/hosts",
             'cd test/e2e',
             'npm install --no-audit --no-fund',
             'npx playwright test --project=desktop',
           ],
         },
       ] else []) + [

    {
        name: "test-upgrade",
        image: "python:3.11-slim-bookworm",
        commands: [
          "APP_ARCHIVE_PATH=$(realpath $(cat package.name))",
          "cd test",
          "./deps.sh",
          "py.test -x -s upgrade.py --distro=buster --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=" + name + ".buster.com --app=" + name
        ],
        privileged: true,
        volumes: [{
            name: "videos",
            path: "/videos"
        }]
    },
        {
      name: 'upload',
      image: 'debian:bookworm-slim',
      environment: {
        AWS_ACCESS_KEY_ID: {
          from_secret: 'AWS_ACCESS_KEY_ID',
        },
        AWS_SECRET_ACCESS_KEY: {
          from_secret: 'AWS_SECRET_ACCESS_KEY',
        },
        SYNCLOUD_TOKEN: {
          from_secret: 'SYNCLOUD_TOKEN',
        },
      },
      commands: [
        'PACKAGE=$(cat package.name)',
        'apt update && apt install -y wget',
        'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
        'chmod +x release',
        './release publish -f $PACKAGE -b $DRONE_BRANCH',
      ],
      when: {
        branch: ['stable', 'master'],
        event: ['push'],
      },
    },
    {
      name: 'promote',
      image: 'debian:bookworm-slim',
      environment: {
        AWS_ACCESS_KEY_ID: {
          from_secret: 'AWS_ACCESS_KEY_ID',
        },
        AWS_SECRET_ACCESS_KEY: {
          from_secret: 'AWS_SECRET_ACCESS_KEY',
        },
        SYNCLOUD_TOKEN: {
          from_secret: 'SYNCLOUD_TOKEN',
        },
      },
      commands: [
        'apt update && apt install -y wget',
        'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
        'chmod +x release',
        './release promote -n ' + name + ' -a $(dpkg --print-architecture)',
      ],
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
        "push",
        "pull_request"
      ]
    },
    services: [
       {
            name: "docker",
            image: "docker:" + dind,
            privileged: true,
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
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
        {
            name: "dockersock",
            temp: {}
        },
    ]
}];

build("amd64", true, "20.10.21-dind") +
build("arm64", false, "19.03.8-dind") +
build("arm", false, "19.03.8-dind")
