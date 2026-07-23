# OpenEMR Production Development Status

## Implemented safely in this release

- Modern responsive bilingual login experience.
- Automatic RTL/LTR direction switching on the login language selector.
- Privacy-safe installable PWA shell that does not cache protected health data.
- Apache production hardening without a restrictive CSP that could break OpenEMR.
- Existing Railway dual-port behavior, healthcheck and persistent volume protections retained.
- Hourly external smoke monitoring through GitHub Actions.
- Pull-request validation for shell, JSON, required files and common secret leaks.
- Encrypted patient-document backup tooling.
- Transaction-safe compressed MySQL backup tooling.
- Backup checksum/decryption verification tooling.
- Non-destructive production readiness diagnostics.
- Arabic/English role matrix and complete clinic workflow runbook.
- No administrator password, MFA, OAuth, login policy or authentication setting changed.
- No patient, appointment, billing, clinical or ACL database row modified.

## Deliberately not auto-applied to production data

The following require a verified administrator session, clinic-specific decisions,
or third-party credentials. Automating them during container startup could create
users, expose patient data, change billing behavior or lock out staff:

- Creating actual staff accounts and assigning ACL groups.
- Facility, provider, specialty, appointment category and service-price setup.
- Enabling individual patient portal accounts.
- SMTP, SMS, WhatsApp Business, payment, laboratory and clearinghouse credentials.
- Country-specific billing codes, insurance rules and tax configuration.
- AI clinical assistant access to patient data.
- Production restore operations.

These items must be configured through a controlled staging-first change process
using the role matrix and workflow documents included in `/opt/openemr-ops`.
