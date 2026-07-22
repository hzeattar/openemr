# OpenEMR on Railway

This repository is configured to deploy OpenEMR from the official stable production Docker image.

## Required Railway services

1. **OpenEMR service** connected to this GitHub repository and the `master` branch.
2. **MySQL database service** named exactly `MySQL`.
3. **Persistent volume** attached to the OpenEMR service at:

```text
/var/www/localhost/htdocs/openemr/sites
```

The volume is required to preserve site configuration and uploaded patient documents across redeployments.

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
OE_PASS=CHANGE_THIS_TO_A_STRONG_PRIVATE_PASSWORD
OPENEMR_SETTING_rest_api=1
```

Keep `OE_PASS` private and seal it in Railway after the first successful deployment.

## Networking

Generate a public Railway domain for the OpenEMR service and set the target port to `80` if Railway does not detect it automatically.

Do not set a custom build command or start command. Railway should detect the root `Dockerfile` and use the official image startup command.

## First deployment

The first deployment performs the OpenEMR database installation automatically. It can take several minutes. The readiness endpoint is:

```text
/meta/health/readyz
```

After deployment, log in with the values of `OE_USER` and `OE_PASS`.

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
