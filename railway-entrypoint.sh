#!/usr/bin/env bash
set -euo pipefail

OE_ROOT="/var/www/localhost/htdocs/openemr"
SITES_DIR="${OE_ROOT}/sites"
SQLCONF_FILE="${SITES_DIR}/default/sqlconf.php"
SEED_DIR="/swarm-pieces/sites"

config_state="0"
if [[ -f "${SQLCONF_FILE}" ]]; then
  config_state=$(php -r "require '${SQLCONF_FILE}'; echo isset(\$config) && \$config ? 1 : 0;" 2>/dev/null | tail -1 || echo 0)
fi

# Railway volumes are bind-mounted empty and, unlike Docker named volumes,
# do not automatically receive the image's pre-populated /sites contents.
# Seed only while OpenEMR is still unconfigured; never overwrite an installed site.
if [[ "${config_state}" != "1" ]]; then
  echo "[railway-init] OpenEMR is not configured; preparing persistent sites volume..."
  mkdir -p "${SITES_DIR}"

  if [[ -d "${SEED_DIR}/default" ]]; then
    rsync --archive --links "${SEED_DIR}/" "${SITES_DIR}/"
  else
    echo "[railway-init] ERROR: OpenEMR seed directory was not found at ${SEED_DIR}" >&2
    exit 1
  fi

  # Prevent the official startup script from treating a brand-new empty
  # Railway volume as an old installation that requires an upgrade.
  if [[ -f /root/docker-version ]]; then
    mkdir -p "${SITES_DIR}/default"
    cp /root/docker-version "${SITES_DIR}/default/docker-version"
  fi

  chown -R apache:apache "${SITES_DIR}"
  echo "[railway-init] Persistent sites volume is ready for first installation."
fi

cd "${OE_ROOT}"
exec ./openemr.sh
