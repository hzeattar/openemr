#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

BACKUP_DIR="${BACKUP_DIR:-/var/backups/openemr/mysql}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

required=(MYSQL_HOST MYSQL_PORT MYSQL_USER MYSQL_PASS MYSQL_DATABASE)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "ERROR: required variable ${name} is missing" >&2
    exit 2
  fi
done

if ! [[ "${RETENTION_DAYS}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: RETENTION_DAYS must be numeric" >&2
  exit 2
fi

DUMP_BIN=""
for candidate in mariadb-dump mysqldump; do
  if command -v "${candidate}" >/dev/null 2>&1; then
    DUMP_BIN="${candidate}"
    break
  fi
done
if [[ -z "${DUMP_BIN}" ]]; then
  echo "ERROR: neither mariadb-dump nor mysqldump is installed" >&2
  exit 3
fi

mkdir -p "${BACKUP_DIR}"
output="${BACKUP_DIR}/openemr-db-${TIMESTAMP}.sql.gz"
tmp="${output}.partial"
trap 'rm -f "${tmp}"' EXIT

export MYSQL_PWD="${MYSQL_PASS}"
"${DUMP_BIN}" \
  --host="${MYSQL_HOST}" \
  --port="${MYSQL_PORT}" \
  --user="${MYSQL_USER}" \
  --single-transaction \
  --quick \
  --routines \
  --triggers \
  --events \
  --hex-blob \
  --default-character-set=utf8mb4 \
  "${MYSQL_DATABASE}" \
  | gzip -9 > "${tmp}"
unset MYSQL_PWD

gzip -t "${tmp}"
mv "${tmp}" "${output}"
sha256sum "${output}" > "${output}.sha256"
find "${BACKUP_DIR}" -type f -name 'openemr-db-*' -mtime "+${RETENTION_DAYS}" -delete
trap - EXIT

echo "Database backup created: ${output}"
