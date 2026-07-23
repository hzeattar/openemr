#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

OE_ROOT="/var/www/localhost/htdocs/openemr"
SITES_DIR="${OE_ROOT}/sites"
SQLCONF_FILE="${SITES_DIR}/default/sqlconf.php"
SEED_DIR="/swarm-pieces/sites"
UPSTREAM_ENTRYPOINT="${OE_ROOT}/openemr.sh"
HTTPD_CONF="/etc/apache2/httpd.conf"
OPENEMR_APACHE_CONF="/etc/apache2/conf.d/openemr.conf"

# Railway healthchecks use the runtime PORT value. Bind Apache to that exact
# port on all IPv4 interfaces instead of relying on OpenEMR's default port 80.
configure_railway_port() {
  local app_port="${PORT:-80}"

  if [[ ! "${app_port}" =~ ^[0-9]+$ ]]; then
    echo "[railway-init] ERROR: PORT must be numeric; received '${app_port}'" >&2
    exit 1
  fi

  local port_number=$((10#${app_port}))
  if (( port_number < 1 || port_number > 65535 )); then
    echo "[railway-init] ERROR: PORT must be between 1 and 65535; received '${app_port}'" >&2
    exit 1
  fi

  if [[ ! -f "${HTTPD_CONF}" || ! -f "${OPENEMR_APACHE_CONF}" ]]; then
    echo "[railway-init] ERROR: Apache configuration files were not found" >&2
    exit 1
  fi

  if grep -q '^Listen 0\.0\.0\.0:80$' "${HTTPD_CONF}"; then
    sed -i "s/^Listen 0\.0\.0\.0:80$/Listen 0.0.0.0:${port_number}/" "${HTTPD_CONF}"
  elif grep -q '^Listen 80$' "${HTTPD_CONF}"; then
    sed -i "s/^Listen 80$/Listen 0.0.0.0:${port_number}/" "${HTTPD_CONF}"
  elif ! grep -q "^Listen 0\.0\.0\.0:${port_number}$" "${HTTPD_CONF}"; then
    echo "[railway-init] ERROR: Could not locate OpenEMR's HTTP Listen directive" >&2
    exit 1
  fi

  if grep -q '<VirtualHost \*:80>' "${OPENEMR_APACHE_CONF}"; then
    sed -i "s#<VirtualHost \*:80>#<VirtualHost *:${port_number}>#" "${OPENEMR_APACHE_CONF}"
  elif ! grep -q "<VirtualHost \*:${port_number}>" "${OPENEMR_APACHE_CONF}"; then
    echo "[railway-init] ERROR: Could not locate OpenEMR's HTTP VirtualHost directive" >&2
    exit 1
  fi

  export PORT="${port_number}"
  echo "[railway-init] Apache configured to listen on 0.0.0.0:${PORT}."
}

# Railway runs this image as a single web-service replica. OpenEMR's upstream
# startup script sets OPERATOR=no when K8S=admin, which completes setup but exits
# before Apache starts. Ignore orchestration flags inherited from Railway
# variables and always run this service as the singleton Apache operator.
if [[ -n "${K8S:-}" || "${SWARM_MODE:-no}" != "no" ]]; then
  echo "[railway-init] Overriding orchestration mode for singleton Railway web service."
fi
unset K8S
export SWARM_MODE="no"

configure_railway_port

is_configured() {
  php -r "if (is_file('${SQLCONF_FILE}')) { require '${SQLCONF_FILE}'; echo isset(\$config) && \$config ? 1 : 0; } else { echo 0; }" \
    2>/dev/null | tail -n 1
}

if [[ ! -d "${SEED_DIR}/default" ]]; then
  echo "[railway-init] ERROR: OpenEMR seed directory was not found at ${SEED_DIR}" >&2
  exit 1
fi

if [[ ! -f /root/docker-version ]]; then
  echo "[railway-init] ERROR: OpenEMR docker version marker is missing" >&2
  exit 1
fi

if [[ ! -x "${UPSTREAM_ENTRYPOINT}" ]]; then
  echo "[railway-init] ERROR: Upstream OpenEMR entrypoint is missing or not executable" >&2
  exit 1
fi

config_state="$(is_configured || true)"

# Railway volumes are bind-mounted empty and, unlike Docker named volumes,
# do not automatically receive the image's pre-populated /sites contents.
# Overlay the official seed only while OpenEMR is unconfigured. No --delete is
# used, so files that do not belong to the seed (including uploaded documents)
# are not removed if this is recovering from an interrupted first installation.
if [[ "${config_state}" != "1" ]]; then
  echo "[railway-init] OpenEMR is not configured; preparing persistent sites volume..."
  mkdir -p "${SITES_DIR}"

  # Remove only orchestration markers from an interrupted setup. Never remove
  # sqlconf.php, documents, or any site data.
  rm -f "${SITES_DIR}/docker-leader" \
        "${SITES_DIR}/docker-initiated" \
        "${SITES_DIR}/docker-completed"

  rsync --archive --links "${SEED_DIR}/" "${SITES_DIR}/"

  # A fresh Railway volume otherwise looks like version 0 to the upstream
  # upgrade detector. Match the image version before first-time auto setup.
  mkdir -p "${SITES_DIR}/default"
  cp /root/docker-version "${SITES_DIR}/default/docker-version"

  chown -R apache:apache "${SITES_DIR}"
  echo "[railway-init] Persistent sites volume is ready for first installation."
else
  echo "[railway-init] Existing OpenEMR configuration detected; preserving persistent sites volume."
fi

cd "${OE_ROOT}"
exec "${UPSTREAM_ENTRYPOINT}"
