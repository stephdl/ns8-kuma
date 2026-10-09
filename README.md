# ns8-uptime-kuma

Uptime Kuma – A Fancy Self-Hosted Monitoring Tool

## Install

Install via Software Center by adding my [repository](https://repo.mrmarkuz.com)

Or on CLI:

    add-module ghcr.io/nethserver/uptime-kuma:latest 1

## Configure

In the app settings at least the FQDN needs to be set.

Uptime Kuma stores its data in a MariaDB container managed by the module, so it does not ask for a database.
SQLite and the embedded MariaDB of Uptime Kuma are not supported. Instances installed before this change start
with an empty MariaDB database: their old data is not migrated.

The first time, the settings page asks for the Uptime Kuma administrator user name and password.
Once the administrator exists the fields are read only: change the password from the Uptime Kuma web page.

If the cluster has a smarthost (Settings > Email notifications), enable "Send alerts through the cluster smarthost" and set one or more recipients.
The module creates a default email notification named "NethServer smarthost" in Uptime Kuma and attaches it to all monitors.
It follows the cluster smarthost settings: change them in NethServer, not in Uptime Kuma.

Example:

    api-cli run module/uptime-kuma1/configure-module --data '{"host": "kuma.example.org", "http2https": true, "lets_encrypt": false, "admin_username": "admin", "admin_password": "Example,Pass1", "smtp_enabled": true, "notification_emails": ["admin@example.org", "ops@example.org"]}'

## Uninstall

The app can be uninstalled by using the Software Center or the CLI:

    remove-module --no-preserve uptime-kuma1

## Testing

Test the module using the `test-module.sh` script:


    ./test-module.sh <NODE_ADDR> ghcr.io/nethserver/uptime-kuma:latest

The tests are made using [Robot Framework](https://robotframework.org/)

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org]((https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
