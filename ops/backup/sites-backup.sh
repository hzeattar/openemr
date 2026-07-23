#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

SITES_DIR="${SITES_DIR:-/var/www/localhost/htdocs/openemr/sites}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/openemr/sites}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

if [[ ! -d "${SITES_DIR}/default" ]]; then
  echo "ERROR: OpenEMR sites directory was not found at ${SITES_DIR}" >&2
  exit 2
fi
if ! [[ "${RETENTION_DAYS}" =~ ^[0-9]+$ ]]; then
  echo "ERROR: RETENTION_DAYS must be numeric" >&2
  exit 2
fi
if [[ -z "${BACKUP_PASSPHRASE:-}" && "${ALLOW_UNENCRYPTED_BACKUP:-no}" != "yes" ]]; then
  echo "ERROR: BACKUP_PASSPHRASE is required for patient-document backups." >&2
  echo "Set ALLOW_UNENCRYPTED_BACKUP=yes only in an already encrypted destination." >&2
  exit 3
fi

mkdir -p "${BACKUP_DIR}"
plain="${BACKUP_DIR}/openemr-sites-${TIMESTAMP}.tar.gz"
plain_tmp="${plain}.partial"
trap 'rm -f "${plain_tmp}" "${plain_tmp}.enc"' EXIT

tar --numeric-owner --one-file-system -C "$(dirname "${SITES_DIR}")" \
  -czf "${plain_tmp}" "$(basename "${SITES_DIR}")"
tar -tzf "${plain_tmp}" >/dev/null

if [[ -n "${BACKUP_PASSPHRASE:-}" ]]; then
  output="${plain}.enc"
  openssl enc -aes-256-cbc -salt -pbkdf2 -iter 200000 \
    -pass env:BACKUP_PASSPHRASE \
    -in "${plain_tmp}" -out "${plain_tmp}.enc"
  mv "${plain_tmp}.enc" "${output}"
  rm -f "${plain_tmp}"
else
  output="${plain}"
  mv "${plain_tmp}" "${output}"
fi

sha256sum "${output}" > "${output}.sha256"
find "${BACKUP_DIR}" -type f -name 'openemr-sites-*' -mtime "+${RETENTION_DAYS}" -delete
trap - EXIT

echo "Sites backup created: ${output}"
