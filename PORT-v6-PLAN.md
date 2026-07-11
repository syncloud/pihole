# Pi-hole snap: v5 → v6 re-port

Branch: `v6-port`. Status: **in progress, driven through Drone CI.**

## Why this is a re-port, not a rebase

A full major version behind, and v6 is a rewrite — the files our fork patches no
longer exist.

| Component | v5 (was) | v6 target |
|---|---|---|
| pi-hole core | 5.16.2 | 6.4.3 |
| FTL | 5.22 (built from source) | 6.7 (prebuilt binary) |
| web | `cyberb/AdminLTE` fork | `pi-hole/web` v6.6 (served by FTL) |

`cyberb/AdminLTE` was 6 ahead / 2134 behind upstream; the whole LDAP patch was
~36 lines in `login.php` + `password.php`, and **both files are deleted in v6**
(PHP AdminLTE replaced by `*.lp` Lua pages served by FTL's embedded web server).
Nothing to rebase onto.

## What v6 changes architecturally

- **One binary.** `pihole-FTL` does DNS + DHCP + embedded web server + REST API +
  bundled `sqlite3`. No PHP, no separate web daemon.
- **One config surface.** `pihole.toml`, plus per-key `FTLCONF_<section>_<key>` env
  overrides (precedence env > toml). Replaces `setupVars.conf`, `pihole-FTL.conf`,
  `dnsmasq.d/*.conf`.
- **Foreground mode.** `pihole-FTL -f` — fits a snap `daemon: simple`.

Almost everything the v5 packaging did with `sed` is now an env var.

## FTL: prebuilt binary, no source build

We **download the official static `pihole-FTL-<arch>` v6.7 binary** from
`github.com/pi-hole/FTL/releases` (sha1-verified, `--version` smoke-checked) — it's
`static-pie` linked, so no libc/link concerns. The v5 packaging only built from
source to patch hardcoded paths into the C (`src/config.c`, `dnsmasq/config.h`);
in v6 those are all `FTLCONF_`/`pihole.toml` settings, so there is nothing to
patch. **Gone:** `ftl/build.sh`, the `pihole-FTL` ld.so wrapper, nettle, cmake, the
`gcc` CI step, and the path-patching seds.

## The three requirements, as implemented

### 1. LDAP / SSO → **Auth A**
The PHP `ldap_bind` patch is dead (no PHP). We run FTL's web with **empty
`FTLCONF_webserver_api_password`** (no pihole login) and gate access at the
platform reverse proxy. nginx binds the platform `web.socket` and proxies to FTL.
**Still to wire:** register/verify the Authelia OIDC/forward-auth in the `configure`
hook (`platformClient.RegisterOIDCClient`) so the proxy actually enforces auth.

### 2. No log files → stdout
`FTLCONF_files_log_ftl=/dev/stdout`; nginx `error_log stderr` / `access_log
/dev/stdout`. Daemons run foreground under snapd → journald. No log files under
`$SNAP_DATA`/`$SNAP_COMMON`.

### 3. Only TCP port 53
- DNS on 53 (default).
- v5's extra port **4711 (telnet API) is gone** in v6.
- FTL web bound to **`127.0.0.1:8080`** (localhost only, not on any real
  interface); nginx on `web.socket` proxies to it. **Open:** if FTL's
  `webserver.port` accepts a unix socket, drop the localhost TCP entirely and bind
  the socket directly — to verify.

## Gravity scheduling — implemented (FTL does NOT schedule it)

v6 still relies on external scheduling (upstream ships `pihole.cron`); host cron
doesn't apply to a confined snap, and the v5 snap had **no** gravity schedule at
all. Implemented `gravity/` — a Go oneshot (`gravity/main.go`) that runs
`$SNAP/bin/pihole -g` (overridable via `GRAVITY_COMMAND`), streams output to
stdout, and on failure logs `update FAILED …` + exits non-zero (`snap logs
pihole.gravity`). Wired as a snap-native weekly timer (`daemon: oneshot`,
`timer: sun,03:00`), built by `gravity/build.sh` (`build gravity` CI step).

## Python hooks → Go CLI — implemented

Per the porting guide, `cli/` (module `hooks`, Cobra + `syncloud/golib`, mirroring
owncast/paperless/bitwarden):
- `installer`: `Install/Configure/StorageChange/AccessChange/UpdateConfigs/
  PostRefresh` + backup-restore; `config.Generate` for templated configs;
  `RunGravity` via `snap run pihole.cli -g` (best-effort).
- `meta/hooks/install|configure` and `hooks/storage-change` now `exec
  $SNAP/bin/cli …`; `snap.yaml` adds `storage-change`/`access-change` apps.
- **Dropped the python component entirely** (dir + CI step + bundled runtime).
- `cli` app stays `bin/pihole` so `snap run pihole.cli -g` and the surviving v5
  seds still resolve.

## Component inventory (actual)

| v5 part | v6 |
|---|---|
| `php-fpm` | **dropped** (no PHP) |
| `sqlite` helper | **dropped** — FTL bundles `pihole-FTL sqlite3` |
| `netcat` helper | **dropped** — v6 status checks in FTL (also broke on bookworm libc) |
| `python` hooks runtime | **dropped** — replaced by Go `cli/` |
| `nginx` | **kept** — binds `web.socket`, proxies to FTL |
| `FTL` from-source | **replaced** with prebuilt v6.7 static binary |
| `cyberb/AdminLTE` (web) | **to do** — swap to `pi-hole/web` v6.6 |
| `bind9` (for `dig.sh`) | kept for now; re-check need under v6 |

## CI modernization — done

The pipeline was pinned to **EOL Debian buster** (apt repos 404). Bumped build
images to `bookworm-slim` and test runners to `python:3.11-slim-bookworm`.
`test`/`test-ui` still target real `*.buster.com` devices + `platform-buster` — the
device-distro layer is the next thing to modernize.

## Remaining work

1. **Core + web to v6.** `download.sh` still pulls pihole core 5.16.2 and the
   cyberb AdminLTE fork; bump core → 6.4.3 and web → `pi-hole/web` v6.6, then strip
   the remaining v5 seds in `build.sh`.
2. **FTL runtime under confinement.** Verify `pihole-FTL -f` starts on the device —
   the hardcoded `/run/pihole-FTL.pid` and the `/etc/pihole`/`/var/log/pihole`
   `layout:` binds are the likely friction; the `test` step is the signal.
3. **Auth A wiring.** Register the OIDC/forward-auth client in `configure` so the
   proxy enforces access.
4. **web.socket direct-bind** for FTL if supported (kill the localhost TCP port).
5. **Device test distro** buster → bookworm (needs a bookworm test device/platform).
6. **Data migration** v5 → v6 (FTL auto-migrates `setupVars.conf` → `pihole.toml`
   on first run; confirm from the snap layout).

## CI cycle log

- #558 buster apt EOL → #559 bookworm bump → #560 drop netcat/sqlite (bookworm
  libc) → #561 python dind race fixed → **v6 FTL snap builds + packages** →
  #562 python→Go cli migration.

## Aside: the v5 field bug

The weekly Android-DNS-drop report
(<https://syncloud.discourse.group/t/pi-hole-once-a-week-stops-android-devices/661>)
looks like FTL going hung-but-alive over ~a week of uptime (likely `/dev/shm`
degradation) that snapd's `restart-condition: always` can't catch. v6 may fix it
incidentally; a v5 stopgap watchdog (`dig @127.0.0.1` → `snap restart pihole.ftl`)
is worth shipping regardless. Needs the user's `pihole-FTL.log` to confirm.
