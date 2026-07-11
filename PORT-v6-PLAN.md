# Pi-hole snap: v5 → v6 re-port plan

Branch: `v6-port`. Status: **plan only, no code changes yet.**

## Why this is a re-port, not a rebase

We are a full major version behind, and v6 is a rewrite — the files our fork
patches no longer exist.

| Component | Ours (vendored) | Upstream latest |
|---|---|---|
| pi-hole core | 5.16.2 | 6.4.3 |
| FTL | 5.22 | 6.7 |
| web (`cyberb/AdminLTE`) | 5.x fork (2023-04) | 6.6 |

`cyberb/AdminLTE` is **6 ahead / 2134 behind** upstream. Our entire LDAP patch is
~36 lines in `login.php` + `scripts/pi-hole/php/password.php`. **Both files are
deleted in v6** — the PHP AdminLTE is gone, replaced by `*.lp` Lua pages served by
FTL's embedded web server hitting a REST API. There is nothing to rebase onto.

## What v6 changes architecturally

- **One binary.** `pihole-FTL` now does DNS + DHCP + **embedded web server** +
  **REST API** + bundled `sqlite3`. No PHP, no separate web daemon required.
- **One config surface.** `/etc/pihole/pihole.toml` (TOML) replaces
  `setupVars.conf`, `pihole-FTL.conf`, and the `dnsmasq.d/*.conf` files.
- **Env overrides.** Every key is settable via `FTLCONF_<section>_<key>` env vars
  (e.g. `FTLCONF_dns_upstreams`, `FTLCONF_webserver_port`,
  `FTLCONF_webserver_api_password`, `FTLCONF_dns_listeningMode`,
  `FTLCONF_misc_dnsmasq_lines`). Precedence: env > toml.
- **Foreground mode.** Runs as `pihole-FTL no-daemon` (`-f`) — a natural fit for a
  snap `daemon: simple`.

This is the direct answer to "is it more configurable now": **yes** — almost
everything we currently achieve with `sed` becomes a `pihole.toml` key or an env
var.

## Your three requirements, mapped to v6

### 1. LDAP / SSO  ← the only genuinely new work
The old approach (patch PHP `verifyPassword` to `ldap_bind`) is dead. Options, in
order of effort:

- **(A) Reverse-proxy gating (lowest effort, recommended to start).** Disable
  pihole's own auth (`FTLCONF_webserver_api_password=""`), bind FTL's web to the
  platform `web.socket`, and let the platform reverse proxy + Authelia gate access.
  Zero pihole code changes. (Porting guide calls forward-auth "old", but for a wrap
  where we run no backend of our own it's pragmatic and safe because the socket is
  never exposed directly.)
- **(B) Small Go OIDC proxy (the "proper" paperless pattern).** A tiny Go binary on
  `web.socket` doing the auth-code+PKCE flow (`RegisterOIDCClient`, `go-oidc`),
  proxying to FTL on an internal socket after auth. More work, cleaner sessions.
- **(C) Platform LDAP.** The porting guide says use LDAP only when the *upstream*
  app has native LDAP support. v6 pihole does **not** (that's why upstream refused
  our patch), and patching FTL's C/Lua auth is far harder than the old PHP one-liner.
  Not recommended.

Decision needed before implementation — default to **(A)**.

### 2. No log files — everything to stdout
v6 still writes `/var/log/pihole/FTL.log` by default. To go stdout-only:
- Point the FTL log at stdout via config (`files.log.ftl` → `/dev/stdout`, or the
  Docker image's `TAIL_FTL_LOG` tail-to-stdout approach), **and**
- keep dnsmasq query logging off / async as today.
Since the daemon runs in foreground under snapd, stdout is captured by journald —
no files under `$SNAP_DATA`/`$SNAP_COMMON`. Verify exact key name for log
redirection during implementation.

### 3. Only TCP port 53
- DNS: `FTLCONF_dns_port=53` (unchanged).
- The old extra port **4711 (telnet API) is gone** in v6.
- The embedded web server is the only other listener: set
  `FTLCONF_webserver_port` to bind the **`web.socket` unix socket** (verify FTL's
  unix-socket bind syntax) so it opens **zero extra TCP ports** and satisfies the
  platform `web.socket` contract at the same time. Fallback if FTL can't bind a
  unix socket: bind `127.0.0.1:<port>` and front it with a thin nginx on
  `web.socket` (still no externally-reachable extra port).

## Gravity scheduling — still needed, FTL does NOT do it

v6 does **not** run gravity on an internal schedule. Upstream still ships
`advanced/Templates/pihole.cron` → `/etc/cron.d/pihole`:
- weekly gravity: `59 1 * * 7 pihole updateGravity`
- daily flush (logrotate): `00 00 * * * pihole flush once quiet`
- `@reboot` logrotate; daily `pihole updatechecker`

Host cron does not apply to a confined snap. Our current v5 snap has **no**
gravity schedule at all (only `hooks/installer.py` on install/refresh), so adlists
never auto-refresh today.

**Implemented** (`gravity/`): a small Go oneshot (`gravity/main.go`) that runs
`$SNAP/bin/pihole -g` (overridable via `GRAVITY_COMMAND`), streams its output to
stdout, and on failure logs `update FAILED …` and exits non-zero so snapd records
the failed run (`snap logs pihole.gravity`). Wired as a snap-native timer:
```yaml
gravity:
  command: bin/gravity
  daemon: oneshot
  timer: sun,03:00
  plugs: [network]
```
Built by `gravity/build.sh` (CI step `build gravity`, `golang:1.22`), copied into
the snap by `build.sh`. Tests pass locally; binary builds static (`CGO_ENABLED=0`).

Confinement note: this works because v6 gravity reloads FTL over the FTL API/unix
socket, so the confined oneshot needs no `snap restart`. Under v5 the sed-rewritten
`snap restart pihole.ftl` inside gravity would fail from a confined daemon — another
reason this belongs with the v6 port.

The `flush`/logrotate crons target the query log file — with the stdout-only goal
they mostly disappear. `updatechecker` is irrelevant for a snap (updates come via
snapd refresh).

## Component inventory: keep / drop / replace

| v5 snap part | v6 |
|---|---|
| `php-fpm` | **drop** (no PHP) |
| `nginx` | **drop if** FTL binds `web.socket` directly; else keep as thin socket proxy |
| `cyberb/AdminLTE` (web) | **replace** with `pi-hole/web` v6 static/`.lp` assets, served by FTL |
| `sqlite` helper | **drop** — use bundled `pihole-FTL sqlite3` |
| `netcat` helper | likely **drop** (v6 status checks moved into FTL) |
| `bind9` (for `dig.sh`) | re-check; fewer scripts shell out to `dig` in v6 |
| `FTL` | **bump 5.22 → 6.7**, now also the web/API server |

## The 34 `sed` rules → where they go in v6

Most disappear. Categories:
- **Path rewrites** (`/etc/pihole`, `/var/log`, `setupVars`, `gravity.db`,
  `piholeDir`, …): replaced by `pihole.toml` paths / env, or by installing under the
  snap layout and pointing config at it. ~20 seds gone.
- **Process control** (`service pihole-FTL restart` → `snap restart`,
  `pidof`/`killall`, `grep -q pihole`): mostly gone — single foreground daemon,
  config reload via API/signal.
- **Port check** (`lsof`→`netstat`, IPv4/IPv6 UDP/TCP munging in `pihole`): v6
  `pihole status` uses FTL directly; drop.
- **Tool shims** (`dig`, `nc`, `sqlite3`, `pihole-FTL sqlite3`): only keep shims for
  tools still shelled out to after the FTL bump.

Target: from **34 seds** down to a handful (or zero) plus a config layer.

## Port sequence

1. `download.sh`: bump `FTL_VERSION=6.7`, `PIHOLE_VERSION=6.4.3`,
   `WEB_VERSION=6.6`; switch web source from `cyberb/AdminLTE` to `pi-hole/web`
   v6.6 (our fork is obsolete). Rebuild 3rdparty artifacts (nettle/FTL) for v6.
2. Drop `php-fpm` + (tentatively) `nginx` from `meta/snap.yaml`; make `ftl` the
   foreground daemon that also serves web/API.
3. Add a generated `pihole.toml` (or an `FTLCONF_*` env block in the service
   wrapper) covering: `dns.upstreams`, `dns.port=53`, `dns.listeningMode`,
   `webserver.port`→socket, `webserver.api.password`, log→stdout, DB path under
   `$SNAP_DATA`.
4. Strip `build.sh` seds down to only what survives; delete config files now owned
   by `pihole.toml` (`01-pihole.conf`, `pihole-FTL.conf`, `dnsmasq.conf`,
   `setupVars.conf.dist`).
5. Wire auth: implement option (A) (or (B)) for OIDC/SSO; drop the dead PHP LDAP
   patch entirely.
6. Update `hooks/installer.py`: config generation on install/refresh, keep
   `run_gravity`, register OIDC client if going with (A)/(B).
7. Update `test/` (UI + integration) for the v6 web (`data-testid`, socket URL) and
   the CI `bookworm + buster` matrix.

## Open questions to resolve during implementation

- Auth: confirm **(A)** vs **(B)**.
- Does FTL v6's `webserver.port` accept a unix-socket bind? (decides nginx keep/drop)
- Exact key to redirect the FTL log to stdout without re-enabling per-query logs.
- Are 3rdparty v6 build artifacts (FTL 6.7, nettle) already published under
  `syncloud/3rdparty`, or do they need rebuilding for arm/amd?
- Data migration: existing users' `gravity.db` / settings v5 → v6 (v6 auto-migrates
  `setupVars.conf`→`pihole.toml` on first run; confirm it works from the snap layout).

## Note on the current v5 field bug

Separately, the weekly Android-DNS-drop report
(<https://syncloud.discourse.group/t/pi-hole-once-a-week-stops-android-devices/661>)
looks like FTL entering a hung-but-alive state over ~a week of uptime (likely
`/dev/shm` shared-memory degradation), which snapd's `restart-condition: always`
can't catch. The v6 port may incidentally fix it, but a v5 stopgap (DNS watchdog
that `snap restart pihole.ftl` on a failed `dig @127.0.0.1`) is worth shipping
regardless. Needs the user's `pihole-FTL.log` to confirm root cause.
