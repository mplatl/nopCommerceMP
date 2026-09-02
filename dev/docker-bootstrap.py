#!/usr/bin/env python3
"""
dev/docker-bootstrap.py — (re-)install + verify the nopCommerce docker stack
for local development of Nop.Plugin.Misc.BusinessCentral.

Prereq:  docker compose up -d --build   (web container exposes port 80)
Usage:   python3 dev/docker-bootstrap.py

What it does:
  1. runs the nopCommerce first-run installer against the SQL Server container
     (demo data + admin account) if the store is not installed yet,
  2. waits for the app to restart after installation,
  3. logs in as admin,
  4. checks the Business Central plugin (installs it if needed),
  5. verifies the plugin config page /Admin/BusinessCentral/Configure.

NOTE: local development credentials only — do not use in production.
"""

import re
import subprocess
import sys
import time

import requests

BASE = "http://localhost"
CONTAINER = "nopcommerce"

# local dev credentials (keep in sync with docker-compose.yml / Installer defaults)
ADMIN_EMAIL = "admin@yourStore.com"
ADMIN_PASSWORD = "NopMP!2025#"
DB_SERVER = "nopcommerce_database"
DB_NAME = "nopCommerce"
DB_USER = "sa"
DB_PASSWORD = "nopCommerce_db_password"
PLUGIN_SYSTEM_NAME = "Misc.BusinessCentral"

s = requests.Session()


def get(url, timeout=60, **kw):
    r = s.get(BASE + url, timeout=timeout, **kw)
    print(f"GET  {url} -> {r.status_code}")
    return r


def token_of(html):
    m = re.search(r'name="__RequestVerificationToken"[^>]*value="([^"]+)"', html)
    return m.group(1) if m else None


def wait_for(url="/", expected=(200,), tries=60, delay=5):
    for i in range(tries):
        try:
            r = s.get(BASE + url, timeout=15, allow_redirects=False)
            if r.status_code in expected:
                return r
        except requests.ConnectionError:
            pass
        time.sleep(delay)
    print(f"Timed out waiting for {url}")
    sys.exit(1)


def docker_start():
    print(f"Starting container {CONTAINER} ...")
    subprocess.run(["docker", "start", CONTAINER], check=True)


def install_store():
    """Run the nopCommerce first-run installation (SQL Server)."""
    print("==> Store not installed, running installer")
    r = get("/install", timeout=30)
    tok = token_of(r.text)
    assert tok, "no antiforgery token on /install"

    form = {
        "__RequestVerificationToken": tok,
        "AdminEmail": ADMIN_EMAIL,
        "AdminPassword": ADMIN_PASSWORD,
        "ConfirmPassword": ADMIN_PASSWORD,
        "DataProvider": "1",  # Microsoft SQL Server
        "ServerName": DB_SERVER,
        "DatabaseName": DB_NAME,
        "Username": DB_USER,
        "Password": DB_PASSWORD,
        "CreateDatabaseIfNotExists": "true",
        "InstallSampleData": "true",
        "SubscribeNewsletters": "false",
        "IntegratedSecurity": "false",
        "ConnectionStringRaw": "false",
        "UseCustomCollation": "false",
        "Country": "US-en-US",
    }
    resp = s.post(BASE + "/install", data=form, timeout=900, allow_redirects=False)
    print("POST /install ->", resp.status_code, resp.headers.get("Location"))

    if "restart" in resp.text.lower():
        print("Installer asks for app restart")
        tok2 = token_of(resp.text) or tok
        s.post(BASE + "/install/restartapplication", data={"__RequestVerificationToken": tok2}, timeout=60)
        # the app shuts down; container may exit without a restart policy handling
        time.sleep(5)
        try:
            s.get(BASE + "/", timeout=5)
        except requests.ConnectionError:
            pass
        docker_start()
    # wait until the app serves the homepage (installer gone)
    wait_for("/", expected=(200,), tries=40, delay=5)
    print("==> Store installed")


def login():
    print("==> Logging in as admin")
    r = get("/login", timeout=30)
    tok = token_of(r.text)
    assert tok
    resp = s.post(BASE + "/login", data={
        "__RequestVerificationToken": tok,
        "Email": ADMIN_EMAIL,
        "Password": ADMIN_PASSWORD,
        "RememberMe": "false",
    }, timeout=60, allow_redirects=False)
    print("POST /login ->", resp.status_code, resp.headers.get("Location"))
    assert resp.status_code == 302
    loc = resp.headers["Location"]
    s.get(loc if loc.startswith("http") else BASE + loc, timeout=60)
    r = s.get(BASE + "/Admin", timeout=60, allow_redirects=False)
    assert r.status_code == 200, "admin area not reachable after login"
    print("==> Admin area reachable")


def plugin_state():
    r = get("/Admin/Plugin/List", timeout=60)
    tok = token_of(r.text)
    data = {
        "draw": 1, "start": 0, "length": 100,
        "SearchLoadModeId": 0, "SearchFriendlyName": "",
        "SearchGroup": "", "SearchAuthor": "",
        "__RequestVerificationToken": tok,
    }
    rj = s.post(BASE + "/Admin/Plugin/ListSelect", data=data, timeout=60)
    rows = rj.json().get("Data", [])
    row = next((x for x in rows if x.get("SystemName") == PLUGIN_SYSTEM_NAME), None)
    return row, tok


def install_plugin(tok):
    print(f"==> Installing plugin {PLUGIN_SYSTEM_NAME}")
    # POST to the list action; the form field name encodes the system name
    resp = s.post(BASE + "/Admin/Plugin/List", data={
        f"install-plugin-link-{PLUGIN_SYSTEM_NAME}": "",
        "__RequestVerificationToken": tok,
    }, timeout=180, allow_redirects=False)
    print("POST /Admin/Plugin/List (install) ->", resp.status_code, resp.headers.get("Location"))
    # installation is finalized on the next app start; give it a moment
    time.sleep(3)


def main():
    # 1) installed? -> installer redirects to /install
    r = s.get(BASE + "/", timeout=30, allow_redirects=False)
    if r.status_code == 302 and "/install" in (r.headers.get("Location") or ""):
        install_store()
    else:
        print("==> Store already installed")

    # 2) login
    login()

    # 3) plugin state / install if needed
    row, tok = plugin_state()
    if row is None:
        print(f"!! Plugin {PLUGIN_SYSTEM_NAME} not found in plugin list")
        sys.exit(1)
    installed = bool(row.get("Installed"))
    print(f"Plugin {PLUGIN_SYSTEM_NAME}: installed={installed}")

    # 4) config page check
    r = s.get(BASE + "/Admin/BusinessCentral/Configure", timeout=60)
    ok = r.status_code == 200 and 'id="configuration-form"' in r.text
    print("Config page /Admin/BusinessCentral/Configure ->", r.status_code,
          "| form ok:", ok)
    if not ok and not installed:
        install_plugin(tok)
        # after install the app usually marks the plugin installed on next run;
        # re-check config page after a short wait
        time.sleep(3)
        r = s.get(BASE + "/Admin/BusinessCentral/Configure", timeout=60)
        print("Config page after install ->", r.status_code,
              "| form ok:", 'id="configuration-form"' in r.text)

    if ok:
        print("\nSUCCESS: Business Central plugin P0 is live on", BASE + "/Admin/BusinessCentral/Configure")
    else:
        print("\nWARNING: config page not fully verified — check the admin UI manually.")


if __name__ == "__main__":
    main()
