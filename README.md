# Necesse Dedicated Server on Coolify

This repository contains a Docker Compose setup for a Necesse dedicated server.
It downloads the official Linux64 server files from the Necesse server page and
exposes the Necesse UDP port directly on the host.

The image is pinned to `linux/amd64`, which matches the Linux dedicated server
package. An amd64 VPS is recommended for Coolify.

## Coolify

1. Create a new Docker Compose resource from this repository.
2. Set `WORLD_NAME` in Coolify environment variables.
3. Optionally set `SERVER_PASSWORD`, `SERVER_OWNER`, `SERVER_SLOTS`, and
   `SERVER_MOTD`.
4. Deploy.
5. Open UDP `${SERVER_PORT}` on the VPS firewall, cloud security group, or any
   tunnel/relay endpoint that forwards traffic to this host.

Coolify's HTTP proxy is not used for this server. Necesse clients connect to
the server IP/domain and UDP port, default `14159`. You normally do not need to
assign a domain in Coolify for this service.

## Optional VPS Tunnel

When home IPv4 port forwarding is not available, enable the bundled WireGuard
client sidecar and publish the server through a VPS relay.

1. Generate a single-line base64 value from the VPS-generated WireGuard client
   config.

```sh
base64 -i data/home-wireguard/wg_confs/wg0.conf | tr -d '\n'
```

On Linux, use:

```sh
base64 -w0 data/home-wireguard/wg_confs/wg0.conf
```

2. Set these Coolify environment variables.

```text
COMPOSE_PROFILES=vps-tunnel
WG0_CONF_B64=<base64 output>
WG_INTERFACE=wg0
```

The `vps-tunnel` service runs in host network mode and uses `privileged: true`
so it can create the WireGuard interface and set the required host sysctl at
container startup. The WireGuard config is stored in the
`necesse-wireguard-client` Docker volume and is not committed to git.

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `WORLD_NAME` | required | World/save name to load or create. |
| `COMPOSE_PROFILES` | empty | Set to `vps-tunnel` to start the bundled WireGuard client sidecar. |
| `WG0_CONF_B64` | empty | Base64-encoded WireGuard `wg0.conf`, required when `COMPOSE_PROFILES=vps-tunnel`. |
| `WG_INTERFACE` | `wg0` | WireGuard interface name used by the sidecar. |
| `PUID` | `1000` | User id passed to the WireGuard sidecar. |
| `PGID` | `1000` | Group id passed to the WireGuard sidecar. |
| `TZ` | `Asia/Tokyo` | Time zone passed to the WireGuard sidecar. |
| `MEMORY_LIMIT` | `1536m` | Container memory limit, tuned to be frugal for about 5 players. |
| `CPU_LIMIT` | `1.0` | Container CPU limit. |
| `SERVER_PORT` | `14159` | UDP port used inside and outside the container. |
| `SERVER_SLOTS` | `5` | Player slots. |
| `SERVER_PASSWORD` | empty | Optional join password. |
| `SERVER_OWNER` | empty | Player name that receives owner permissions. |
| `SERVER_MOTD` | empty | Message of the day. Use `\n` for new lines. |
| `PAUSE_WHEN_EMPTY` | `1` | Pause simulation when no players are online. |
| `GIVE_CLIENTS_POWER` | `0` | Necesse client-action checking setting. |
| `SERVER_LOGGING` | `1` | Enable server log files. |
| `ZIP_SAVES` | `1` | Store saves compressed. |
| `JVM_XMS` | `256M` | Initial JVM heap size. |
| `JVM_XMX` | `1024M` | Maximum JVM heap size, leaving headroom under the container memory limit. |
| `JAVA_OPTS` | empty | Extra Java options, split on spaces. |
| `AUTO_UPDATE` | `1` | Check the official server page on start and download only when the cached server files are missing or outdated. |
| `SERVER_DOWNLOAD_PAGE` | `https://necessegame.com/server/` | Page used to resolve the latest Linux64 server zip. |
| `SERVER_DOWNLOAD_URL` | empty | Optional direct zip URL override. |
| `EXTRA_ARGS` | empty | Extra Necesse server args, split on spaces. |

## Local Run

Use `.env.example` as a template for local environment variables, then run:

```sh
docker compose up --build
```

Server files are cached in the `necesse-server-files` Docker volume. Save data,
configs, and logs are stored in the `necesse-data` Docker volume at
`/home/necesse/.config/Necesse` inside the container. With `AUTO_UPDATE=1`,
starts check the official server page and skip the full download when the cached
server version is already current.
