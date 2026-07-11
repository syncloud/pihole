local name = "pihole";
local browser = "firefox";
local platform = '26.04.10';
local selenium = '4.21.0-20240517';
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
            name: "selenium",
            image: "selenium/standalone-" + browser + ":" + selenium,
            detach: true,
            environment: {
                SE_NODE_SESSION_TIMEOUT: "999999",
                START_XVFB: "true"
            },
               volumes: [{
                name: "shm",
                path: "/dev/shm"
            }],
            commands: [
                "cat /etc/hosts",
                "getent hosts " + name + ".buster.com | sed 's/" + name +".buster.com/auth.buster.com/g' | sudo tee -a /etc/hosts",
                "cat /etc/hosts",
                "/opt/bin/entry_point.sh"
            ]
         },
     {
           name: 'selenium-video',
           image: 'selenium/video:ffmpeg-6.1.1-20240517',
           detach: true,
           environment: {
             DISPLAY_CONTAINER_NAME: 'selenium',
             FILE_NAME: 'video.mkv',
           },
           volumes: [
             {
               name: 'shm',
               path: '/dev/shm',
             },
             {
               name: 'videos',
               path: '/videos',
             },
           ],
         },
         {
           name: 'test-ui',
           image: 'python:3.11-slim-bookworm',
           commands: [
             'cd test',
             "getent hosts " + name + ".buster.com | sed 's/" + name +".buster.com/auth.buster.com/g' | tee -a /etc/hosts",       
             './deps.sh',
             'py.test -x -s ui.py --distro=buster --ui-mode=desktop --domain=buster.com --device-host=' + name + '.buster.com --app=' + name + ' --browser-height=3000 --browser=' + browser,
           ],
           volumes: [{
             name: 'videos',
             path: '/videos',
           }],
         },

       ] else []) + [

    {
        name: "test-upgrade",
        image: "python:3.11-slim-bookworm",
        commands: [
          "APP_ARCHIVE_PATH=$(realpath $(cat package.name))",
          "cd test",
          "./deps.sh",
          "py.test -x -s upgrade.py --distro=buster --ui-mode=desktop --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=" + name + ".buster.com --app=" + name + " --browser=" + browser
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
