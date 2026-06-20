#!/usr/bin/env bash
set -Eeuo pipefail

: "${WORLD_NAME:?WORLD_NAME is required}"

SERVER_DIR="${SERVER_DIR:-/opt/necesse/server}"
AUTO_UPDATE="${AUTO_UPDATE:-1}"
SERVER_DOWNLOAD_PAGE="${SERVER_DOWNLOAD_PAGE:-https://necessegame.com/server/}"
SERVER_DOWNLOAD_URL="${SERVER_DOWNLOAD_URL:-}"
SERVER_PORT="${SERVER_PORT:-14159}"
SERVER_SLOTS="${SERVER_SLOTS:-5}"
SERVER_PASSWORD="${SERVER_PASSWORD:-}"
SERVER_OWNER="${SERVER_OWNER:-}"
SERVER_MOTD="${SERVER_MOTD:-}"
PAUSE_WHEN_EMPTY="${PAUSE_WHEN_EMPTY:-1}"
GIVE_CLIENTS_POWER="${GIVE_CLIENTS_POWER:-0}"
SERVER_LOGGING="${SERVER_LOGGING:-1}"
ZIP_SAVES="${ZIP_SAVES:-1}"
JVM_XMS="${JVM_XMS:-256M}"
JVM_XMX="${JVM_XMX:-1024M}"
JAVA_OPTS="${JAVA_OPTS:-}"
EXTRA_ARGS="${EXTRA_ARGS:-}"
SERVER_VERSION_FILE="${SERVER_DIR}/.necesse-server-version"
LATEST_DOWNLOAD_URL=""
LATEST_SERVER_VERSION=""

resolve_server_download() {
  local download_url="${SERVER_DOWNLOAD_URL}"
  local page_file

  if [[ -z "${download_url}" ]]; then
    echo "Resolving latest Necesse Linux64 server download..."
    page_file="$(mktemp)"
    if ! curl -fsSL "${SERVER_DOWNLOAD_PAGE}" -o "${page_file}"; then
      rm -f "${page_file}"
      return 1
    fi
    download_url="$(grep -m 1 -o 'https://necesse-website[^"<>]*necesse-server-linux64-[^"<>]*\.zip[^"<>]*' "${page_file}" | sed 's/&amp;/\&/g' || true)"
    rm -f "${page_file}"
  fi

  if [[ -z "${download_url}" ]]; then
    echo "Could not resolve Necesse Linux64 server download URL." >&2
    return 1
  fi

  LATEST_DOWNLOAD_URL="${download_url}"
  LATEST_SERVER_VERSION="${download_url%%\?*}"
  LATEST_SERVER_VERSION="${LATEST_SERVER_VERSION##*/}"
}

install_server() {
  local tmp_dir
  local server_jar

  tmp_dir="$(mktemp -d)"
  echo "Downloading Necesse server files ${LATEST_SERVER_VERSION}..."
  if ! curl -fL "${LATEST_DOWNLOAD_URL}" -o "${tmp_dir}/necesse-server.zip"; then
    rm -rf "${tmp_dir}"
    return 1
  fi

  mkdir -p "${tmp_dir}/extract"
  if ! unzip -q "${tmp_dir}/necesse-server.zip" -d "${tmp_dir}/extract"; then
    rm -rf "${tmp_dir}"
    return 1
  fi

  server_jar="$(find "${tmp_dir}/extract" -name Server.jar -type f -print -quit)"
  if [[ -z "${server_jar}" ]]; then
    echo "Downloaded archive did not contain Server.jar." >&2
    rm -rf "${tmp_dir}"
    return 1
  fi

  find "${SERVER_DIR:?}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
  cp -a "$(dirname "${server_jar}")/." "${SERVER_DIR}/"
  printf '%s\n' "${LATEST_SERVER_VERSION}" > "${SERVER_VERSION_FILE}"
  rm -rf "${tmp_dir}"
}

if [[ "${AUTO_UPDATE}" == "1" || ! -f "${SERVER_DIR}/Server.jar" ]]; then
  installed_version=""
  if [[ -f "${SERVER_VERSION_FILE}" ]]; then
    installed_version="$(<"${SERVER_VERSION_FILE}")"
  fi

  if ! resolve_server_download; then
    if [[ -f "${SERVER_DIR}/Server.jar" ]]; then
      echo "Update check failed; starting the previously downloaded server files." >&2
    else
      exit 1
    fi
  elif [[ -f "${SERVER_DIR}/Server.jar" && "${installed_version}" == "${LATEST_SERVER_VERSION}" ]]; then
    echo "Necesse server files already current (${LATEST_SERVER_VERSION})."
  elif ! install_server; then
    if [[ -f "${SERVER_DIR}/Server.jar" ]]; then
      echo "Update failed; starting the previously downloaded server files." >&2
    else
      exit 1
    fi
  fi
fi

cd "${SERVER_DIR}"

server_args=(
  -nogui
  -world "${WORLD_NAME}"
  -port "${SERVER_PORT}"
  -slots "${SERVER_SLOTS}"
  -pausewhenempty "${PAUSE_WHEN_EMPTY}"
  -giveclientspower "${GIVE_CLIENTS_POWER}"
  -logging "${SERVER_LOGGING}"
  -zipsaves "${ZIP_SAVES}"
)

if [[ -n "${SERVER_PASSWORD}" ]]; then
  server_args+=(-password "${SERVER_PASSWORD}")
fi

if [[ -n "${SERVER_OWNER}" ]]; then
  server_args+=(-owner "${SERVER_OWNER}")
fi

if [[ -n "${SERVER_MOTD}" ]]; then
  server_args+=(-motd "${SERVER_MOTD}")
fi

java_args=(-Xms"${JVM_XMS}" -Xmx"${JVM_XMX}")

if [[ -n "${JAVA_OPTS}" ]]; then
  read -r -a extra_java_args <<< "${JAVA_OPTS}"
  java_args+=("${extra_java_args[@]}")
fi

if [[ -n "${EXTRA_ARGS}" ]]; then
  read -r -a extra_server_args <<< "${EXTRA_ARGS}"
  server_args+=("${extra_server_args[@]}")
fi

exec java "${java_args[@]}" -jar Server.jar "${server_args[@]}"
