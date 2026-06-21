# Necesse Dedicated Server on Coolify

This repository contains a Docker Compose setup for a Necesse dedicated server.
It downloads the official Linux64 server files from the Necesse server page and
exposes the Necesse UDP port directly on the host.

The image is pinned to `linux/amd64`, which matches the Linux dedicated server
package. An amd64 VPS is recommended for Coolify.

## Coolify

1. Create a new Docker Compose resource from this repository.
2. Set `WORLD_NAME` in Coolify environment variables.
3. Set `PLAYIT_SECRET_KEY` to the secret key generated for your playit agent.
4. Optionally set `SERVER_PASSWORD`, `SERVER_OWNER`, `SERVER_SLOTS`, and
   `SERVER_MOTD`.
5. Deploy.

Coolify's HTTP proxy is not used for this server. Necesse clients connect to
the playit address and UDP port. You normally do not need to assign a domain in
Coolify for this service.

## playit Tunnel

The `playit` service runs the official playit agent container with host
networking. In playit's dashboard, create a Necesse or custom UDP tunnel with:

| Setting | Value |
| --- | --- |
| Local address | `127.0.0.1` |
| Local port | `${SERVER_PORT}` / `14159` by default |
| Protocol | UDP |

The Necesse container still publishes UDP `${SERVER_PORT}` on the Linux host, so
the playit agent can reach it at `127.0.0.1:${SERVER_PORT}`. Router port
forwarding and Coolify's HTTP proxy are not required for the playit path.

## Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `WORLD_NAME` | required | World/save name to load or create. |
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
| `PLAYIT_SECRET_KEY` | required | Secret key for the playit agent. Generate it in playit's dashboard. |

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
