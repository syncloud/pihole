# Pi-hole snap: v5 → v6 re-port — COMPLETE

Branch: `v6-port`. Status: **done — full CI green on amd64 + armv7 (build #590).**
arm64 stage is `pending` only because that runner is busy; not a code issue.

## Result

A from-scratch re-port of the Syncloud Pi-hole snap from v5.16.2 to **v6.4.3 /
FTL v6.7 / pi-hole web v6.6**, behind platform SSO, exposing only port 53.
Every CI step passes on amd64 and armv7: `build`, `package`, integration `test`
(9), Playwright `e2e`, and `test-upgrade` (v5→v6).

## What changed vs v5

| Area | v5 | v6 (now) |
|---|---|---|
| FTL | built from source (nettle/cmake/gcc) | **prebuilt static `pihole-FTL-<arch>` v6.7** (sha1-verified) |
| Hooks | Python (`syncloudlib`) | **Go CLI** (`cli/`, cobra + `golib`) with snapd `install`/`configure` hooks |
| Gravity | none scheduled | **Go oneshot** on a weekly snap `timer` |
| Web | AdminLTE (PHP) + php-fpm | FTL-embedded web (`/admin/`), **php dropped** |
| nginx | `syncloud/3rdparty` (no auth_request) | **official `nginx:1.24.0`** (has `http_auth_request_module`) |
| Config | `setupVars`/`01-pihole.conf` + 34 `sed`s | `pihole.toml` + `FTLCONF_`/`--config`, `/etc/pihole` host symlinks; few `sed`s |
| Auth | LDAP patch in PHP login | **nginx `auth_request` → Authelia** (no OIDC in FTL) |
| UI tests | selenium (`ui.py`) | **Playwright** (`test/e2e/`, Authelia login) |
| CI base | Debian buster (EOL) | bookworm; platform test image `26.04.10` |
| Ports | 53 + 4711 + web | **only 53 external**; FTL web on `127.0.0.1:8080` behind nginx `web.socket` |

## Auth-A (the auth question, answered)

Pi-hole v6 / FTL has **no OIDC** (`webserver.api.*` is password/session/TOTP
only). So the app is gated with **nginx forward-auth to the platform Authelia**,
mirroring navidrome:
- `config/authelia-location.conf` — internal `/internal/authelia/authz` →
  `{{ .AuthLocalSocket }}/api/authz/auth-request`
- `config/authelia-authrequest.conf` — `auth_request` + `401 → 302` to Authelia
- installer generates `AuthUrl` (`GetAppUrl("auth")`) + `AuthLocalSocket`
  (golib bumped 1.1.15 → 1.1.17)
- unauthenticated `/admin/` → 302 to Authelia; Playwright logs in via the portal

## Snap layout

- `ftl` (daemon): `pihole-FTL -f` with `FTLCONF_` env + `--config` for
  webserver.port/webroot; sets up `/etc/pihole`, `/var/log/pihole`,
  `/run/pihole-FTL.pid → $SNAP_COMMON/ftl.pid` symlinks per invocation
  (snapd gives each `snap run` a fresh mount ns; Syncloud snapd doesn't apply
  `layout:`).
- `nginx` (daemon): binds `$SNAP_COMMON/web.socket`, forward-auths to Authelia,
  proxies `/admin/` + API to FTL `127.0.0.1:8080`, `/ → /admin/`.
- `gravity` (oneshot + `timer: sun,03:00`) → `service.cli.sh -g`.
- `cli` = `bin/service.cli.sh` (sets up paths, execs the v6 `pihole` script).
- `storage-change` / `access-change` = `bin/cli …`.
- snapd hooks `meta/hooks/{install,configure}` → `$SNAP/bin/cli …`.

## Known follow-ups (non-blocking)

- **Dashboard live stats**: the `e2e` smoke asserts the dashboard *renders*
  after login; it does not yet assert live numbers. Earlier the FTL API showed
  `Error (-2)` unauthenticated — revisit whether it fully populates through the
  authenticated proxy and, if so, tighten the spec to assert `#gravity_size` as
  a number.
- **arm64**: runner currently busy; stage will pass when it picks up (armv7 +
  amd64 already validate the build).

## CI cycle log

#558 buster-EOL → bookworm; drop php/sqlite/netcat/python; platform image
26.04.10; snapd refresh held; prebuilt FTL; Go CLI + hooks; `/etc/pihole`
symlinks; FTL webserver 8080 + webroot; nginx redirect/logging; **first full
green #583**; selenium → Playwright (#584); auth-request → Authelia + official
nginx (#589–590).
