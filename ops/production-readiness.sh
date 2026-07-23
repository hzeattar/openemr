#!/usr/bin/env bash
set -Eeuo pipefail

OE_ROOT="${OE_ROOT:-/var/www/localhost/htdocs/openemr}"
failed=0

pass() { printf '[PASS] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; failed=1; }
notice() { printf '[INFO] %s\n' "$*"; }

[[ -f "${OE_ROOT}/sites/default/sqlconf.php" ]] && pass 'OpenEMR site configuration exists' || fail 'sqlconf.php is missing'
[[ -d "${OE_ROOT}/sites/default/documents" ]] && pass 'Patient documents directory exists' || fail 'documents directory is missing'
[[ -w "${OE_ROOT}/sites/default/documents" ]] && pass 'Documents directory is writable by the current execution context' || notice 'Documents directory is not writable by this user; verify it is writable by apache'
[[ -f "${OE_ROOT}/manifest.webmanifest" ]] && pass 'PWA manifest installed' || fail 'PWA manifest missing'
[[ -f "${OE_ROOT}/service-worker.js" ]] && pass 'Privacy-safe service worker installed' || fail 'Service worker missing'
[[ -f "/etc/apache2/conf.d/zz-openemr-security.conf" ]] && pass 'Apache hardening installed' || fail 'Apache hardening missing'
[[ -f "${OE_ROOT}/railway-health" ]] && pass 'Railway health file exists' || fail 'Railway health file missing'

if command -v curl >/dev/null 2>&1; then
  port="${PORT:-80}"
  if curl --fail --silent --max-time 10 "http://127.0.0.1:${port}/railway-health" | grep -Fxq ok; then
    pass "Local healthcheck responds on port ${port}"
  elif [[ "${port}" != '80' ]] && curl --fail --silent --max-time 10 'http://127.0.0.1:80/railway-health' | grep -Fxq ok; then
    pass 'Local healthcheck responds on fallback port 80'
  else
    fail 'Local healthcheck did not return ok'
  fi
else
  notice 'curl is not installed; local HTTP check skipped'
fi

if command -v mysqladmin >/dev/null 2>&1 && [[ -n "${MYSQL_HOST:-}" && -n "${MYSQL_USER:-}" && -n "${MYSQL_PASS:-}" ]]; then
  MYSQL_PWD="${MYSQL_PASS}" mysqladmin ping \
    --host="${MYSQL_HOST}" --port="${MYSQL_PORT:-3306}" --user="${MYSQL_USER}" --silent \
    && pass 'MySQL connection succeeded' \
    || fail 'MySQL connection failed'
else
  notice 'MySQL variables/client unavailable; database connectivity check skipped'
fi

if (( failed != 0 )); then
  echo 'Production readiness checks failed.' >&2
  exit 1
fi

echo 'Production readiness checks completed successfully.'
