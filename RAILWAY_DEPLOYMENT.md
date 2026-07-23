# OpenEMR on Railway

This repository deploys OpenEMR from the official stable production Docker image.

## Required Railway services

1. **OpenEMR service** connected to this GitHub repository and the `master` branch.
2. **MySQL database service** named exactly `MySQL`.
3. **Persistent volume** attached to the OpenEMR service at:

```text
/var/www/localhost/htdocs/openemr/sites
```

The volume preserves site configuration and uploaded patient documents across redeployments. Railway bind mounts start empty, so `railway-entrypoint.sh` safely overlays the official `/swarm-pieces/sites` skeleton only while OpenEMR is unconfigured. It never uses `rsync --delete` and does not replace an installed site.

## OpenEMR service variables

Open the OpenEMR service, go to **Variables**, then use the RAW editor and add:

```dotenv
PORT=80
MYSQL_HOST=${{MySQL.MYSQLHOST}}
MYSQL_PORT=${{MySQL.MYSQLPORT}}
MYSQL_ROOT_USER=${{MySQL.MYSQLUSER}}
MYSQL_ROOT_PASS=${{MySQL.MYSQLPASSWORD}}
MYSQL_USER=${{MySQL.MYSQLUSER}}
MYSQL_PASS=${{MySQL.MYSQLPASSWORD}}
MYSQL_DATABASE=${{MySQL.MYSQLDATABASE}}
OE_USER=admin
OE_USER_NAME=Administrator
OE_PASS=CHANGE_THIS_TO_A_STRONG_PRIVATE_PASSWORD
MANUAL_SETUP=no
OPENEMR_SETTING_rest_api=1
RAILWAY_HEALTHCHECK_TIMEOUT_SEC=900
```

Confirm the actual variable names exposed by the MySQL service before applying the references. In particular, do not assume the service user is `root`; `MYSQL_ROOT_USER` must be an account that can perform the initial database setup.

Keep `OE_PASS` private and seal it in Railway after the first successful deployment. Do not set `SWARM_MODE=yes` for this single-replica Railway deployment; the custom entrypoint already handles the empty bind-mounted volume.

## Networking

Generate a public Railway domain for the OpenEMR service and set the target port to `80`. Do not set a custom build command or start command; Railway should use the root `Dockerfile` and its `CMD`.

The deployment healthcheck is a static Apache endpoint:

```text
/railway-health
```

It must return HTTP `200` with body `ok`. This endpoint deliberately avoids the database-backed OpenEMR readiness route, while Apache still starts only after the upstream setup script has completed.

## First deployment

The first deployment performs the OpenEMR database installation automatically and may take several minutes. In deploy logs, verify this sequence:

```text
Waiting for MySQL...
MySQL is ready!
Running quick setup!
OpenEMR configured successfully
Setup Complete!
Starting Apache!
```

After deployment, log in with `OE_USER` and `OE_PASS`.

## Create a normal user

After logging in as administrator:

1. Open **Administration**.
2. Open **Users**.
3. Select **Add User**.
4. Create the required physician, clinician, or staff account and assign only the permissions it needs.

Do not use the administrator account for routine clinical work.

## Production notes

- Keep the MySQL database and OpenEMR volume in the same Railway project.
- Enable Railway backups for the database and volume before storing real patient data.
- Rotate the administrator password after first login.
- Do not commit passwords, database credentials, private keys, or patient data to GitHub.
