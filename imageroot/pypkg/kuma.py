#
# Copyright (C) 2026 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

import subprocess


def sql(query):
    """Run SQL on the Uptime Kuma database and return the raw output."""
    cmd = ["podman", "exec", "-i", "uptime-kuma-mariadb", "sh", "-c",
           'MYSQL_PWD="${MARIADB_ROOT_PASSWORD}" exec mariadb -N -B -uroot "${MARIADB_DATABASE}"']
    proc = subprocess.run(cmd, input=query, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError("SQL query failed: " + proc.stderr)
    return proc.stdout.strip()


def text_literal(value):
    # A hex literal avoids any quoting issue with user supplied values
    return f"CONVERT(X'{value.encode().hex()}' USING utf8mb4)"


def admin_username():
    """Name of the Uptime Kuma admin, None if it does not exist or the database is not ready."""
    try:
        return sql("SELECT username FROM user ORDER BY id LIMIT 1;") or None
    except Exception:
        return None


def need_setup(timeout=5):
    """True if Uptime Kuma has no user yet, None if the server is unreachable."""
    proc = subprocess.run(["kuma-admin", "need-setup", str(timeout)], capture_output=True, text=True)
    if proc.returncode != 0:
        return None
    return proc.stdout.strip() == "true"
