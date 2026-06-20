FROM debian:bookworm-slim

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    SERVER_DIR=/opt/necesse/server

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      openjdk-17-jre-headless \
      tini \
      unzip; \
    rm -rf /var/lib/apt/lists/*; \
    groupadd --gid "${GID}" necesse; \
    useradd --uid "${UID}" --gid "${GID}" --create-home --shell /bin/bash necesse; \
    mkdir -p "${SERVER_DIR}" /home/necesse/.config/Necesse; \
    chown -R necesse:necesse /opt/necesse /home/necesse

COPY --chown=necesse:necesse entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER necesse:necesse
WORKDIR /opt/necesse/server

EXPOSE 14159/udp

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
