#!/usr/bin/env python3
"""
dev/test-bc-connection.py — end-to-end test of the P1 "Test connection" flow
of Nop.Plugin.Misc.BusinessCentral against the local nopCommerce docker stack.

Credentials are read from the environment (never stored in this repo):
    BC_TEST_TENANT_ID, BC_TEST_ENV, BC_TEST_CLIENT_ID, BC_TEST_CLIENT_SECRET, BC_TEST_COMPANY

Usage:  python3 dev/test-bc-connection.py
"""

import os
import re
import sys

import requests

BASE = "http://localhost"
ADMIN_EMAIL = "admin@yourStore.com"
ADMIN_PASSWORD = "NopMP!2025#"

CREDS = {
    "TenantId": os.environ.get("BC_TEST_TENANT_ID", ""),
    "EnvironmentName": os.environ.get("BC_TEST_ENV", ""),
    "ClientId": os.environ.get("BC_TEST_CLIENT_ID", ""),
    "ClientSecret": os.environ.get("BC_TEST_CLIENT_SECRET", ""),
    "CompanyName": os.environ.get("BC_TEST_COMPANY", ""),
}
if not all(CREDS.values()):
    print("missing BC_TEST_* environment variables")
    sys.exit(1)

s = requests.Session()


def token_of(html):
    # attribute order varies; grab the whole input tag first, then its value
    m = re.search(r'<input[^>]*name="__RequestVerificationToken"[^>]*>', html)
    if not m:
        return None
    v = re.search(r'value="([^"]+)"', m.group(0))
    return v.group(1) if v else None


def login():
    r = s.get(BASE + "/login", timeout=30)
    tok = token_of(r.text)
    assert tok, "no antiforgery token on /login"
    resp = s.post(BASE + "/login", data={
        "__RequestVerificationToken": tok,
        "Email": ADMIN_EMAIL,
        "Password": ADMIN_PASSWORD,
        "RememberMe": "false",
    }, timeout=60, allow_redirects=False)
    assert resp.status_code == 302, f"login failed: {resp.status_code}"
    print("logged in as admin")


def test_connection():
    r = s.get(BASE + "/Admin/BusinessCentral/Configure", timeout=60)
    assert r.status_code == 200, "config page not reachable"
    tok = token_of(r.text)
    assert tok, "no antiforgery token on config page"

    form = {
        "__RequestVerificationToken": tok,
        "Enabled": "true",
        "UseSandbox": "true",
        "TenantId": CREDS["TenantId"],
        "EnvironmentName": CREDS["EnvironmentName"],
        "ClientId": CREDS["ClientId"],
        "ClientSecret": CREDS["ClientSecret"],
        "CompanyName": CREDS["CompanyName"],
        "LogSyncMessages": "false",
        "RequestTimeout": "30",
    }
    resp = s.post(BASE + "/Admin/BusinessCentral/TestConnection", data=form, timeout=120)
    print("POST /Admin/BusinessCentral/TestConnection ->", resp.status_code)

    page = resp.text
    # success notification (rendered by the returned configure view)
    m = re.search(r"The connection to Business Central was established successfully\. Available companies: ([^<]+)\.", page)
    if m:
        print("SUCCESS: connection OK, companies found:", m.group(1))
        return 0
    if "established successfully" not in page:
        for msg in re.findall(r'(?:error|alert-danger)[^>]*>(.*?)<', page, re.I)[:5]:
            print("ERROR on page:", msg.strip()[:200])
    print("FAIL: success message not found on the page")
    return 1


if __name__ == "__main__":
    login()
    sys.exit(test_connection())
