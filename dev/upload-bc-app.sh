#!/usr/bin/env bash
# dev/upload-bc-app.sh — upload + deploy a compiled AL .app to a Business Central CLOUD sandbox
# via the Automation API (extensionUpload media entity: create -> stream PUT -> Microsoft.NAV.upload action).
#
# Credentials via env (never hardcode):
#   BC_TENANT_ID, BC_ENV, BC_CLIENT_ID, BC_CLIENT_SECRET   (app registration w/ Automation.ReadWrite.All)
# Usage:
#   BC_TENANT_ID=... BC_ENV=sandbox29 BC_CLIENT_ID=... BC_CLIENT_SECRET=... \
#     ./dev/upload-bc-app.sh bc-app/nopCommerceConnector/nopCommerceConnector.app "CRONUS AT"
set -euo pipefail

APP="${1:?usage: upload-bc-app.sh <file.app> [company]}"
COMPANY="${2:-CRONUS AT}"
: "${BC_TENANT_ID:?set BC_TENANT_ID}" "${BC_ENV:?set BC_ENV}"
: "${BC_CLIENT_ID:?set BC_CLIENT_ID}" "${BC_CLIENT_SECRET:?set BC_CLIENT_SECRET}"

AUTH="https://login.microsoftonline.com/$BC_TENANT_ID/oauth2/v2.0/token"
B="https://api.businesscentral.dynamics.com/v2.0/$BC_TENANT_ID/$BC_ENV/api/microsoft/automation/v2.0"
CQ="company=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$COMPANY")"

echo "== Token =="
TOKEN=$(curl -s -m 30 -X POST "$AUTH" -d "client_id=$BC_CLIENT_ID" -d "client_secret=$BC_CLIENT_SECRET" \
  -d "scope=https://api.businesscentral.dynamics.com/.default" -d "grant_type=client_credentials" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['access_token'])")

echo "== 1) extensionUpload anlegen =="
curl -s -m 60 -X POST "$B/extensionUpload?$CQ" -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"schedule":"Current version","schemaSyncMode":"Add"}' -o /tmp/bcupload.json -w "HTTP %{http_code}\n"
ID=$(python3 -c "import json;print(json.load(open('/tmp/bcupload.json'))['systemId'])")
echo "systemId=$ID"

echo "== 2) .app-Stream hochladen =="
curl -s -m 60 "$B/extensionUpload($ID)?$CQ" -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" > /tmp/bcupload_ent.json
ETAG=$(python3 -c "import json;print(json.load(open('/tmp/bcupload_ent.json'))['@odata.etag'])")
curl -s -o /dev/null -m 600 -X PUT "$B/extensionUpload($ID)/extensionContent?$CQ" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/octet-stream" -H "If-Match: $ETAG" \
  --data-binary @"$APP" -w "HTTP %{http_code}\n"

echo "== 3) Deployment (Microsoft.NAV.upload) =="
curl -s -o /dev/null -m 600 -X POST "$B/extensionUpload($ID)/Microsoft.NAV.upload?$CQ" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{}' -w "HTTP %{http_code}\n"

echo "== Deployment-Status (Polling 3 min) =="
for i in $(seq 1 6); do
  sleep 30
  curl -s -m 60 "$B/extensionDeploymentStatus?$CQ" -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
    | python3 -c "import sys,json;[print(x['name'], x['publisher'], x['status'], x['appVersion']) for x in json.load(sys.stdin).get('value',[])]"
done
