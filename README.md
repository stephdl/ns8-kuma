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

`host` is required. `admin_username` and `admin_password` go together. The other fields keep their current
value when they are left out. HTTP is always redirected to HTTPS.

### Database

Uptime Kuma stores its data in a MariaDB 11.4 LTS container managed by the module.
The module passes the database settings to Uptime Kuma, so its first start does not ask for a database.
SQLite and the embedded MariaDB of Uptime Kuma are not supported.

### Administrator

The module creates the administrator through the Uptime Kuma setup API on the first configuration.
The Settings page asks for at least 8 characters with lowercase, uppercase, digit and symbol.
The API only rejects what Uptime Kuma calls too weak: less than 6 characters, or a single kind of character.
Once the administrator exists, the Settings page shows its name read only.
Change the user name or the password from the Uptime Kuma web page.

### Email alerts

When the cluster has a smarthost (Settings > Email notifications), the "Send alerts through the cluster
smarthost" toggle can be enabled, with one or more recipients. The toggle cannot be turned on while the
cluster has no smarthost. Recipients go one per line, commas and spaces are accepted too.

The module then keeps a notification named "NethServer smarthost" in Uptime Kuma:

- it is the default notification, attached to every existing monitor when it is created
- its SMTP settings follow the cluster smarthost, and change when the smarthost changes
- it is removed when the toggle is disabled or the cluster smarthost is turned off, and created again when
  the smarthost comes back
- alerts are sent from `kuma@<domain>`, where the domain is the host name without its first label
  (`kuma.example.org` sends from `kuma@example.org`), so the smarthost must accept that sender

Edit the smarthost in NethServer, not this notification in Uptime Kuma: the next sync overwrites it.
Other notifications, for example Telegram, are added from the Uptime Kuma web page and are never touched.

## Backup, restore and clone

The backup saves `state/database.env`, the `kuma-data` volume and a `mariadb-dump` of the database
(`state/kuma.sql`, taken by `module-dump-state` and removed after the backup). The `mariadb-data` volume itself
is not saved. The backup fails with a clear message when the MariaDB container is not running.

A restore loads the dump into a new MariaDB volume, then reconfigures the module with the saved host,
Let's Encrypt and email settings. The administrator comes back with the database. A restore fails if the
backup has no dump.

A clone copies the state and the volumes, then reconfigures the module the same way. The clone keeps the
host name of the source: change it before using both instances.

## Update

`update-module` installs the new image and restarts the three services. The data stays in the `mariadb-data` and `kuma-data` volumes.

Renovate keeps MariaDB on the 11.4 LTS branch: a move to another major version needs a dump and restore.

## Services

| Unit | Container | Role |
| --- | --- | --- |
| `kuma.service` | pod `kuma` | Podman pod, publishes Uptime Kuma on the module TCP port |
| `kuma-mariadb.service` | `kuma-mariadb` | MariaDB 11.4, volume `mariadb-data` |
| `kuma-app.service` | `kuma-app` | Uptime Kuma 2.x, volume `kuma-data` |

Every Save in the Settings page restarts the three services.

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
