#!/usr/bin/env bash
# dev/build-bc-app.sh — compile the "nopCommerce Connector" AL app (.app) with altool
# Symbols: platform 28.0.53152.0 + application 28.4.53241.0 (local artifact downloads)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/bc-app/nopCommerceConnector"
AL_TOOL="${AL_TOOL:-$HOME/.vscode/extensions/ms-dynamics-smb.al-17.0.2273547/bin/linux/altool}"

cd "$APP_DIR"
"$AL_TOOL" compile "/project:$APP_DIR" "/packageCachePath:$APP_DIR/.alpackages" "/out:$APP_DIR/nopCommerceConnector.app"

echo
echo "OK: $APP_DIR/nopCommerceConnector.app"
