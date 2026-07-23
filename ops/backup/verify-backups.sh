#!/usr/bin/env bash
set -Eeuo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/openemr}"
status=0

if [[ ! -d "${BACKUP_ROOT}" ]]; then
  echo "ERROR: backup root does not exist: ${BACKUP_ROOT}" >&2
  exit 2
fi

while IFS= read -r checksum; do
  echo "Verifying checksum: ${checksum}"
  (cd "$(dirname "${checksum}")" && sha256sum -c "$(basename "${checksum}")") || status=1
done < <(find "${BACKUP_ROOT}" -type f -name '*.sha256' -print | sort)

while IFS= read -r dump; do
  echo "Testing database archive: ${dump}"
  gzip -t "${dump}" || status=1
done < <(find "${BACKUP_ROOT}" -type f -name 'openemr-db-*.sql.gz' -print | sort)

while IFS= read -r archive; do
  echo "Testing sites archive: ${archive}"
  tar -tzf "${archive}" >/dev/null || status=1
done < <(find "${BACKUP_ROOT}" -type f -name 'openemr-sites-*.tar.gz' ! -name '*.enc' -print | sort)

while IFS= read -r encrypted; do
  if [[ -z "${BACKUP_PASSPHRASE:-}" ]]; then
    echo "NOTICE: encrypted archive checksum verified; set BACKUP_PASSPHRASE to test decryption: ${encrypted}"
    continue
  fi
  echo "Testing encrypted sites archive: ${encrypted}"
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
    -pass env:BACKUP_PASSPHRASE -in "${encrypted}" \
    | tar -tzf - >/dev/null || status=1
done < <(find "${BACKUP_ROOT}" -type f -name 'openemr-sites-*.tar.gz.enc' -print | sort)

exit "${status}"
