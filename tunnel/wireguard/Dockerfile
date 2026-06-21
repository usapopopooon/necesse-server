FROM lscr.io/linuxserver/wireguard:latest

COPY tunnel/wireguard/entrypoint.sh /usr/local/bin/necesse-wireguard-entrypoint
RUN chmod 755 /usr/local/bin/necesse-wireguard-entrypoint

ENTRYPOINT ["/usr/local/bin/necesse-wireguard-entrypoint"]
