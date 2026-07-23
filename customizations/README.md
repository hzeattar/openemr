# Project customization overlay

This directory contains project-owned overlays copied on top of the official
`openemr/openemr:8.2.0` image during Docker build. Keeping custom files here makes
changes visible, reviewable and reversible without editing patient data or the
persistent `sites` volume.

- `login/`: Twig login templates; authentication behavior remains in official partials.
- `pwa/`: installable shell metadata; no application or patient response is cached.
- `apache/`: conservative security headers and server-information hardening.

Before changing the pinned OpenEMR image, compare each overlaid upstream file and
validate the login page in staging.
