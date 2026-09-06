# Betrieb: Hetzner /nop1 (Subdirectory-Hosting) — Fixes & Wissen

> **Status:** live · letzte Aktualisierung 06.09.2026
> Store: **https://project-discovery.ddns.net/nop1** (leere DB, nopCommerce 4.90.7, net9.0)
> ERP-Plattform: **https://project-discovery.ddns.net/** (unverändert, läuft parallel)
> Dieses Dokument ist die **Gedächtnis-Stütze** für die drei kritischen Fixes — Details & WARUM, nie entfernen ohne erneutes Durchdenken.

---

## 1. Architektur (Ist-Zustand)

| Teil | Wert |
|---|---|
| Server | `erp-server` (Hetzner, 2 vCPU / 3,7 GB RAM + **4 GB Swap-Datei**), Ubuntu |
| Reverse-Proxy | **Caddy in Docker** (erp-discovery-Stack) — **nicht nginx**! Ports 80/443 |
| Caddyfile | `/opt/erp-discovery/frontend/Caddyfile` (ro in Container gemountet), Backups als `Caddyfile.bak.*` |
| nopCommerce | `/opt/nop1` = git clone (privates Repo, Deploy-Key `~/.ssh/nopcommerce_deploy`, SSH-Alias `github-nop1`) |
| Compose | `/opt/nop1/docker-compose.prod.yml` (Projektname `nop1`) |
| Container | `nop1_web` (Image `nop1-web:latest`, Build aus `./src`) + `nop1_mssql` (SQL Server 2019 Express) |
| Netzwerk | beide im **externen** Netz `erp-discovery_default` (`172.18.0.0/16`) — **keine** öffentlichen Ports |
| Volumes | `nop1_appdata` (= `/app/App_Data`), `nop1_mssql` |
| DB | leer (kein Demodata), Name `nopCommerce`, SA-Passwort nur in `/opt/nop1/.env` (chmod 600) |
| Admin | `admin@yourStore.com` / `NopMP!2025#` (Demo — in Produktion ändern!) |

**Caddy-Routen (Reihenfolge im Site-Block ist wichtig):**

```caddy
project-discovery.ddns.net {
    handle /api/*        { reverse_proxy backend:8000 }        # ERP-Backend (unangetastet)
    handle_path /nop1*   { reverse_proxy nop1_web:80 {         # nopCommerce
                            header_up X-Forwarded-Prefix /nop1
                          } }
    handle /icons/*      { reverse_proxy nop1_web:80 }         # Favicons (werden ohne /nop1 generiert)
    handle { root * /usr/share/caddy; ... }                    # ERP-SPA-Catch-all (zuletzt!)
}
```

> ⚠️ `header_up` ist eine Sub-Directive **innerhalb von `reverse_proxy`**, nicht von `handle_path` (Caddy-Validate schlägt sonst fehl).
> ⚠️ `handle_path` **strippt** `/nop1` und `header_up X-Forwarded-Prefix /nop1` stellt es der App wieder her.

---

## 2. Fix 1 — PathBase/Proxy (Commit `b88eab7`)

**Problem:** App lief ohne Kenntnis von `/nop1` → Links/Redirects/Schema falsch (`http://…/install` statt `https://…/nop1/install`).

**3 Teile:**
1. Source-Patch `src/Presentation/Nop.Web.Framework/Infrastructure/Extensions/ApplicationBuilderExtensions.cs` (`UseNopProxy`):
   `ForwardedHeaders = XForwardedFor | XForwardedProto | **XForwardedPrefix**`
2. `App_Data/appsettings.json` → `HostingConfig`: `UseProxy: true`, `KnownNetworks: "172.18.0.0/16"` (Caddy-Netz)
3. Caddy: `handle_path /nop1*` + `header_up X-Forwarded-Prefix /nop1` (s. o.)

**Fallstricke (Warum so?):**
- nopCommerce bindet IConfig-Sektionen über `IConfig.Name` = **voller Klassenname** → `"HostingConfig"`, **nicht** `"Hosting"`. Env-Variablen `Hosting__*` greifen also **nicht**; es zählt `App_Data/appsettings.json`.
- Der **Installer überschreibt `appsettings.json` mit Code-Defaults** (UseProxy=false) → nach jeder Neuinstallation Fixes erneut anwenden (`fix-config.sh`).
- `KnownNetworks` akzeptiert CIDR (`"172.18.0.0/16`), `KnownProxies` nur Einzel-IPs.

---

## 3. Fix 2 — Icons/Fonts (WebOptimizer AUS)

**Symptom:** Alle Admin-Icons (Font Awesome, inkl. (i)-Info-Icon) nur Platzhalter.

**Root Cause (wichtig!):** WebOptimizer schreibt beim Bundling/Processing alle `url()`/`@font-face`-Referenzen in CSS **wurzel-relativ** um (`../../lib_npm/…`). Unter einem Path-Base (`/nop1`) löst der Browser das gegen `https://domain/lib_npm/…` auf (ohne `/nop1`) → ERP-SPA-Catch-all liefert **HTML statt Font** → „font network error“, alle Glyphen = `.notdef`.

**Fix:** `App_Data/appsettings.json` → `WebOptimizer`:
```json
"WebOptimizer": {
  "EnableCssBundling": false,
  "EnableJavaScriptBundling": false
}
```
Zusätzlich nötig: `wwwroot/bundles/*` leeren (WebOptimizer-Disk-Cache enthielt stale, falsch umgeschriebene CSS) + Container-Neustart.

**Warum beide Flags?** Nur CSS auszuschalten reicht NICHT: solange der WebOptimizer-Pipeline (wegen JS) registriert ist, werden auch Einzel-CSS-Dateien „verarbeitet“ und Pfade erneut falsch umgeschrieben. Beide `false` ⇒ Dateien werden **roh** vom Static-File-Middleware ausgeliefert ⇒ originale relative Pfade bleiben korrekt unter `/nop1`.

> ⚠️ **Achtung Konfig-Key:** Sektion heißt hier `"WebOptimizer"` (übersteuertes `Name`, NICHT `WebOptimizerConfig`)!
> Browser-Cache: nach Icon-Fixes **Hard Refresh** (Ctrl/Cmd+Shift+R) nötig.

---

## 4. Fix 3 — Plugin-Konfig-URL (Commit `0557e83`)

**Symptom:** „Configure“-Button des Business-Central-Plugins → `/Admin/BusinessCentral/ListSelect` → 404.

**Root Cause:** `BusinessCentralPlugin.GetConfigurationPageUrl()` rief
`RouteUrl(ConfigurationRouteName)` **ohne explizite Route-Values** auf. Auf der Plugin-List-Seite (`/Admin/Plugin/ListSelect`) gewinnt der **Ambient-Wert `action=ListSelect`** der aktuellen Route über den Route-Default `action=Configure` → URL `…/ListSelect`.

**Fix:** Action explizit übergeben:
```csharp
return _nopUrlHelper.RouteUrl(BusinessCentralDefaults.ConfigurationRouteName, new { action = "Configure" });
```

**Lesson (generalisieren!):** `RouteUrl(routeName)` **ohne Values** ist nur sicher, wenn die Ambient-Werte des aktuellen Requests (controller/action/area) zu den Ziel-Route-Defaults passen. Im Admin-Kontext (Listen mit `…Select`-Actions!) immer die Ziel-Action mitgeben. Dieser Bug existierte auch lokal — er fiel nur auf, weil die Dev-Bootstrap-Doku `/Configure` direkt aufrief statt den Button zu klicken.

---

## 5. Betriebs-Skripte (nur auf dem Server, nicht im Repo — `/opt/nop1`)

| Skript | Zweck |
|---|---|
| `install_empty.py` | Leere-DB-Installation über den Web-Installer (liest SA-Passwort aus `.env`) |
| `fix-config.sh` | Wendet Fix 1 (HostingConfig) + Fix 2 (WebOptimizer off) nach Reinstall an, leert `wwwroot/bundles`, Restart |
| `docker-compose.prod.yml` + `.env` | Prod-Compose (keine Host-Ports, externes Netz, Mem-Limits: db 2 GB / web 1 GB) |
| `.venv` | Python mit `requests` + **Playwright/Chromium** (Headless-Render-Verifikation, s. §6) |

**Befehle:**
```bash
# Neu-Deploy (Code-Änderung)
ssh erp-server "cd /opt/nop1 && git pull && docker compose -f docker-compose.prod.yml build web \
  && docker compose -f docker-compose.prod.yml up -d --force-recreate web"

# Reinstall (leere DB)
ssh erp-server "cd /opt/nop1 && docker compose -f docker-compose.prod.yml down -v \
  && docker compose -f docker-compose.prod.yml up -d && python3 install_empty.py && ./fix-config.sh"

# Caddy-Reload (nach Caddyfile-Edit)
ssh erp-server "docker exec erp-discovery-web-1 caddy reload --config /etc/caddy/Caddyfile"
```

---

## 5b. Plugin-BC-API-Config (Live) & Produktbilder

- Plugin-Settings liegen in `Setting` (DB): `businesscentralsettings.companyname` muss exakt dem BC-Firmennamen entsprechen (**`CRONUS AT`**, Sandbox) — stand auf `CRONUS AG` und lies den Company-Resolver (`ResolveCompanyAsync`) fehlschlagen ⇒ Bild-Anhang beim Produkt-Push & Catalog-Sync schlugen fehl.
  Fix: `UPDATE Setting SET Value='CRONUS AT' WHERE Name='businesscentralsettings.companyname'` + Container-Restart.
- Produkt-Push (`POST /api/bc/products`) hängt seit Commit `5884226` automatisch das erste BC-Artikelbild an (best effort, nur wenn das Produkt noch keins hat; `VisibleIndividually` wird dabei auch geheilt). Artikel ohne BC-Bild bleiben ohne Bild.

## 6. Fehlerdiagnose-Lektionen

1. **Reverse Proxy ist Caddy, nicht nginx** — immer `docker ps`/`docker network ls` prüfen.
2. **HTTP-Checks reichen nicht** für CSS/Font-Probleme — echte Browser-Verifikation nötig
   (`/opt/nop1/.venv`: Playwright/Chromium; `document.fonts.check(...)`, Canvas-Glyph-Probe, Screenshots).
3. nopCommerce-Konfig: IConfig-Sektion = Klassenname (`HostingConfig`, …), Ausnahme `WebOptimizer`.
4. Caddy-Fehler „unrecognized directive header_up“ → falsche Verschachtelung (s. §1).
5. RAM-Planung: SQL Express limitiert sich selbst (~1,4 GB), Mem-Limits + Swap halten den 3,7-GB-Server am Leben.
6. Verifikations-Workflow nach Install/Restart: Shop 200 + ERP `/` 200 + Admin-Login + Font-URLs unter `/nop1/…`.

---

## 7. Wichtigste Commits

| Commit | Inhalt |
|---|---|
| `b88eab7` | `UseNopProxy`: `XForwardedPrefix` mit-forwarden (Path-Base unter `/nop1`) |
| `0557e83` | Plugin: `GetConfigurationPageUrl()` mit explizitem `action = "Configure"` (Fix 404 `/…/ListSelect`) |

Konfig-Änderungen (HostingConfig/WebOptimizer/Caddyfile) leben **außerhalb** des Repos — siehe `fix-config.sh`/Caddyfile-Auszug §1.
