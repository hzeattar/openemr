# OpenEMR Backup Operations | عمليات النسخ الاحتياطي

This directory provides explicit, non-automatic backup tools. They never change
OpenEMR authentication and are not executed during application startup.

يوفر هذا المجلد أدوات نسخ احتياطي صريحة وغير تلقائية. لا تغيّر الأدوات مصادقة
OpenEMR ولا تعمل أثناء بدء تشغيل التطبيق.

## Required coverage | نطاق النسخة المطلوبة

A complete restore requires both of the following at the same recovery point:

1. MySQL database backup.
2. Persistent `sites` directory backup, including patient documents.

الاستعادة الكاملة تحتاج نسخة قاعدة MySQL ونسخة مجلد `sites` في نقطة زمنية متقاربة.

## Database backup

```bash
BACKUP_DIR=/secure-backups/mysql \
RETENTION_DAYS=14 \
/opt/openemr-ops/backup/mysql-backup.sh
```

The script reads the existing `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`,
`MYSQL_PASS`, and `MYSQL_DATABASE` variables. It produces a compressed dump and
SHA-256 checksum using a transaction-safe dump.

## Sites and documents backup

Patient documents must be encrypted unless the destination is already encrypted:

```bash
export BACKUP_PASSPHRASE='use-a-secret-from-a-secret-manager'
BACKUP_DIR=/secure-backups/sites \
RETENTION_DAYS=14 \
/opt/openemr-ops/backup/sites-backup.sh
unset BACKUP_PASSPHRASE
```

The passphrase must be stored in Railway secrets or another secret manager, not
in GitHub, documentation, shell history, or chat messages.

## Verification

```bash
BACKUP_ROOT=/secure-backups /opt/openemr-ops/backup/verify-backups.sh
```

For encrypted archives, export `BACKUP_PASSPHRASE` before verification to test
both checksum and decryption.

## Railway deployment recommendation

- Enable Railway database backups for the MySQL service.
- Enable volume backups for the OpenEMR volume when supported by the plan.
- Run these scripts from a dedicated cron/backup service with an encrypted,
  persistent destination.
- Keep at least one off-project copy.
- Test restoration in a separate staging environment every quarter.
- Never test restoration against production.
