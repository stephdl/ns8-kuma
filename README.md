# ns8-kuma

[Uptime Kuma](https://github.com/louislam/uptime-kuma) for NethServer 8: a self-hosted monitoring tool
for websites, ports, mail servers and certificates.

This module started as a fork of [mrmarkuz/ns8-uptime-kuma](https://github.com/mrmarkuz/ns8-uptime-kuma).
It has its own name, `kuma`, so both modules can be installed on the same cluster.

## Install

    add-module ghcr.io/stephdl/kuma:latest 1

The output gives the instance name, for example `kuma1`.

## Configure

Open the app Settings page in the cluster admin and set:

- the host name (FQDN) of the web interface, with an optional Let's Encrypt certificate
- the Uptime Kuma administrator user name and password, asked only the first time
- in Advanced, the email alerts sent through the cluster smarthost

The same settings on the command line:

    api-cli run module/kuma1/configure-module --data '{
      "host": "kuma.example.org",
      "lets_encrypt": false,
      "admin_username": "admin",
      "admin_password": "Example,Pass1",
      "smtp_enabled": true,
      "notification_emails": ["admin@example.org", "ops@example.org"]
    }'

Fields that are left out keep their current value. HTTP is always redirected to HTTPS.

### Database

Uptime Kuma stores its data in a MariaDB 11.4 LTS container managed by the module.
The module passes the database settings to Uptime Kuma, so its first start does not ask for a database.
SQLite and the embedded MariaDB of Uptime Kuma are not supported.

### Administrator

The module creates the administrator through the Uptime Kuma setup API on the first configuration.
The password must not be weak (at least 6 characters from 2 kinds among lowercase, uppercase, digits and symbols).
Once the administrator exists, the Settings page shows its name read only.
Change the user name or the password from the Uptime Kuma web page.

### Email alerts

When the cluster has a smarthost (Settings > Email notifications), the "Send alerts through the cluster
smarthost" toggle can be enabled, with one or more recipients. The toggle is disabled while the cluster has
no smarthost.

The module then keeps a notification named "NethServer smarthost" in Uptime Kuma:

- it is the default notification, attached to every existing monitor when it is created
- its SMTP settings follow the cluster smarthost, and change when the smarthost changes
- it is removed when the toggle is disabled or the cluster smarthost is turned off

Other notifications, for example Telegram, are added from the Uptime Kuma web page and are never touched.

## Backup, restore and clone

The backup saves a `mariadb-dump` of the database, taken by `module-dump-state`. The backup fails with a clear
message when the MariaDB container is not running. A restore loads the dump into a new MariaDB volume, then
reconfigures the module with the saved host and email settings. A clone copies the database with the volumes.

## Update

`update-module` writes the Uptime Kuma database settings and restarts the three services. An instance
installed before the MariaDB container starts on an empty database: old SQLite data is not migrated.

## Services

| Unit | Container | Role |
| --- | --- | --- |
| `kuma.service` | pod `kuma` | Podman pod, publishes Uptime Kuma on the module TCP port |
| `kuma-mariadb.service` | `kuma-mariadb` | MariaDB 11.4, volume `mariadb-data` |
| `kuma-app.service` | `kuma-app` | Uptime Kuma 2.x, volume `kuma-data` |

Useful commands:

    runagent -m kuma1 systemctl --user status kuma-app.service
    api-cli run module/kuma1/get-configuration

## Uninstall

    remove-module --no-preserve kuma1

## Testing

The [Robot Framework](https://robotframework.org/) suite in `tests/` runs on the NethServer QEMU CI after each
image publication, on Rocky Linux 9 and Debian 13. It installs and configures an instance, checks the
administrator, MariaDB, HTTPS, the email settings, the backup dump and a clone, takes screenshots of the UI,
then removes the instance. The update scenario is off until the module is published in a repository.

To run it against a test node, use the shared runner of ns8-github-actions:

    curl -sSL https://raw.githubusercontent.com/NethServer/ns8-github-actions/v1/scripts/test-module.sh -o /tmp/test-module.sh
    SSH_KEYFILE=~/.ssh/id_rsa RUN_UI_TESTS=false bash /tmp/test-module.sh <NODE_ADDR> ghcr.io/stephdl/kuma:latest

## UI development

The UI is built with Vue 2, ns8-ui-lib 2 and yarn 4 (pinned in `ui/package.json`, enabled with corepack).
`build-images.sh` builds it in a `node:24-slim` container.

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org](https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
