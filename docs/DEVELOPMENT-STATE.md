# Development State — Business Central Plugin (nopCommerceMP)

> **Letzte Aktualisierung:** 04.09.2026 (P1 live verifiziert; BC-App „nopCommerce Connector“ Iteration A+B Teil 1)
> Nächster Schritt: BC-App auf Sandbox `sandbox29` publizieren (braucht einmalige Freigabe, siehe §4) + Iteration B fortsetzen

## Hosting/Fixes (Hetzner /nop1) — Lessons, nie wieder vergessen!
0. **Reverse Proxy ist Caddy, nicht nginx**; nopCommerce läuft unter `https://project-discovery.ddns.net/nop1`.
1. **WebOptimizer MUSS komplett aus sein** (`EnableCssBundling: false` **und** `EnableJavaScriptBundling: false`):
   er schreibt `url()`/`@font-face`-Pfade wurzel-relativ um → unter Path-Base laden Fonts nicht → **alle Icons = Platzhalter**.
2. **`RouteUrl(name)` ohne explizite Values = Fallstrick**: Ambient-Werte (z. B. `action=ListSelect` auf der Plugin-List-Seite)
   gewinnen über Route-Defaults → immer Ziel-Action mitgeben (`new { action = "Configure" }`, Commit `0557e83`).
3. **Installer schreibt `App_Data/appsettings.json` mit Code-Defaults** → nach Reinstall Fixes erneut anwenden
   (`/opt/nop1/fix-config.sh`: HostingConfig-Proxy + WebOptimizer off + Bundles leeren).
   Details & Warum: [`docs/hetzner-subdirectory-deployment.md`](hetzner-subdirectory-deployment.md) (Commit `b88eab7` = X-Forwarded-Prefix).

---

## AL-Regeln für die BC-App (Lessons — nie wieder verletzen!)
1. **Neue GUID je App** (`app.json` id) — nie kopieren.
2. **ID-Bereich nicht bei 50000/50100 starten**; Projekt nutzt **62100–62300** (Konflikt mit GLAccount Workflow 50100–50109 vermeiden).
3. **`ApplicationArea = All;` auf Objektebene** (Seiten), sonst PTE0008 bei Cloud-Validierung; Cops (CodeCop/PerTenantExtensionCop/UICop) via `.vscode/settings.json` aktiviert.
4. Erst lokal publizieren/validieren (MsDyn365Bc.On.Linux), dann SaaS; Automation-Upload-Queue nicht mit Wiederholungen verkleben.

---

## 1. Was fertig ist

| Bereich | Stand |
|---|---|
| **Konzept** | `docs/business-central-plugin-concept.md` — Plugin-Architektur, BC-API, Roadmap P0–P8 |
| **Feature-Referenz** | `docs/bc-connector-feature-parity.md` — vollständige Parität mit dem BC-Shopify-Connector (aus BC-Quellcode 28.4.53241.0 abgeleitet), nop-Mapping, Lücken |
| **P0 Plugin-Skelett** | `src/Plugins/Nop.Plugin.Misc.BusinessCentral/` — plugin.json, csproj, Plugin-Klasse, Settings, Defaults, Controller, Models, Views, Infrastructure (RouteProvider, NopStartup) |
| **Solution** | Projekt in `src/NopCommerce.sln` (Lösungsordner „Plugins") — kompletter Solution-Build: **0 Fehler** |
| **Docker-Test** | nopCommerce 4.90.7 lokal im Docker installiert (Demo-Daten) — Plugin installiert + Config-Seite `/Admin/BusinessCentral/Configure` **200 ✓** |
| **P1c Nop-Languages je Shop** | BC-App 1.0.12.0: Tabelle `Nop Language` (je Shop, nop Language ID), Seite `Nop Commerce Languages`, Aktionen „Languages“ (Shop-Card, Shops-Liste, RoleCenter), Default-Sprache je Shop — Basis für sprachspezifische Produkttext-Syncs (Pull via Plugin-API + HTTP-Infra folgt) |
| **Iteration B Teil 1 — Transport + Languages-Pull** | BC-App 1.0.13.0 + Plugin: `GET /api/bc/languages` (Plugin, X-Api-Key); AL `Nop Commerce Http` (62120, HttpClient, X-Api-Key); `Test Connection` jetzt real (GET /health); `SyncLanguages` (Pull → `Nop Language`, Default bleibt erhalten); Aktionen „Get Languages“ (Shop-Card + Shops-Liste). Offen: Produkt-Push `POST /api/bc/products`, Orders/Customers-Pull |
| **Kunden-Logins (Debitor) je Shop** | BC-App 1.0.24.0: Tabelle `Nop Customer Login` (62116) mit PK `(Shop Code, Customer No., E-mail)` ⇒ mehrere Logins je Debitor (eine Zeile je E-mail/Login); Seite `Nop Commerce Customers` (Setup + Shops-Liste). Alte Tabelle `Nop Customer` (62114) obsolete (PK-Änderung an installierter Tabelle ist in Cloud nicht erlaubt). Offen: Login-Transfer nach nop (Plugin-Endpoint) |
| **Delete/Deaktivieren Store Products** | BC-App 1.0.21.0: **Löschen** einer Store-Product-Zeile = nur Liste entfernen (kein nop-Aufruf, kein Fehler im OnDelete). **Inaktiv-Setzen in nop passiert beim Push** über den Status (Archived → remove=true → `Published=false`; Historie/Warenkorb bleiben unberührt, kein hartes Löschen). Offen: Variante „sichtbar aber nicht kaufbar“ (`DisableBuyButton`) nach Entscheidung |
| **Action-Areas** | BC-App 1.0.19.0: Processing = nur ausführende Aktionen (Get Languages, Push Products, Test Connection); Navigation = Daten öffnen (Products, Search & Add Items, Saved Filters, Languages) — RoleCenter nutzt Embedding |
| **Store-Products-Navigation** | BC-App 1.0.18.0: Store Products nur noch über die Shop-Karte (Setup) — Aktionen aus RoleCenter- und Shops-Listen-Menü entfernt; Spalte „Shop Code“ in der Store-Products-Liste entfernt (Seite wird gefiltert vom Store geöffnet) |
| **RoleCenter-Stapel** | BC-App 1.0.17.0: Cue „Shops“ (Tabelle `Nop Commerce Cue` 62113 mit FlowField `Shop Count`, CardPart `Nop Commerce Shop Cue` 62121, DrillDownPageID → Shops-Liste) — Klick auf den Stapel öffnet die Shops |
| **Iteration B Teil 2 — Produkt-Push (BC → nop)** | BC-App 1.0.14.0: `Nop Commerce Http.Post` (JSON-Body, Content-Type); `PushProducts` exportiert `Nop Product`-Zeilen je Shop via `POST /api/bc/products` (Draft/Active → published, Archived → remove=true; Erfolg → Status Active + nop Product Id; Fehler → Last Sync Error); Aktion „Push Products“ (Shop-Card + Shops-Liste). Offen: Preis/Lager-Felder (kultursichere Dezimal-Serialisierung), Orders/Customers-Pull |
| **Dev-Skript** | `dev/docker-bootstrap.py` — automatisiert Erstinstallation, Login, Plugin-Install/-Check (idempotent) |

## 2. Umgebung & Zugangsdaten (nur lokale Entwicklung!)

- Shop: http://localhost · Admin: http://localhost/Admin
- **Admin:** `admin@yourStore.com` / `NopMP!2025#`
- **SQL Server:** Container `nopcommerce_mssql_server`, `sa` / `nopCommerce_db_password`, DB `nopCommerce` (Demo-Daten)
- Docker-Volumes: `nopcommercemp_nopcommerce_data` (persistente DB), `restart: unless-stopped` gesetzt
- .NET SDK 9.0.317 installiert unter `~/.dotnet` (global.json verlangt 9.x; nur SDK 8 war vorinstalliert)

## 3. Wiederaufnahme (nach Reboot / neuer Shell)

```bash
cd ~/Dokumente/git_private/nopCommerceMP
docker compose up -d --build          # Web + DB starten (baut nur beim ersten Mal neu)
# Shop ist bereits installiert → nur Login nötig:
python3 dev/docker-bootstrap.py       # verifiziert Login + Plugin + Config-Seite
```

Falls die DB/Installation fehlt (z. B. Volume gelöscht): `python3 dev/docker-bootstrap.py` macht die komplette Erstinstallation automatisch.

**Plugin bauen (nach Code-Änderungen):**
```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet build src/NopCommerce.sln -v minimal          # ganzer Build (empfohlen)
# oder nur das Plugin (Achtung: -p:SolutionDir nötig):
dotnet build src/Plugins/Nop.Plugin.Misc.BusinessCentral/Nop.Plugin.Misc.BusinessCentral.csproj -p:SolutionDir="$PWD/src/"
docker compose up -d --build                          # neue DLL ins Image bringen
```

## 4. Nächster Schritt: P1 — Connection

**Benötigt vom Kunden/Benutzer:**
1. BC-Umgebung: Tenant-ID, Environment-Name (Sandbox/Production), Company-Name
2. Entra-ID-App: Client-ID + Client-Secret (im BC-Tenant registriert, Berechtigung `Dynamics 365 Business Central → API.ReadWrite.All`, Admin-Consent)

**Umsetzung P1 (in `src/Plugins/Nop.Plugin.Misc.BusinessCentral/`):**
- `Services/BusinessCentralHttpClient.cs` — OAuth2 Client-Credentials (Token-Endpoint `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token`, Scope `https://api.businesscentral.dynamics.com/.default`), Token-Cache, Basis-URL `https://api.businesscentral.dynamics.com/v2.0/{tenant}/{env}/api/v2.0`
- `Services/BusinessCentralService.cs` — `TestConnectionAsync()` (Unternehmen-Liste `GET companies`), `IsConfigured()`
- Config-Seite: „Test Connection"-Button + Statusanzeige, Validierung
- Registrierung in `Infrastructure/NopStartup.cs` (`AddHttpClient<BusinessCentralHttpClient>().WithProxy()`)
- Konstanten in `BusinessCentralDefaults.cs` sind vorbereitet (TokenEndpoint, ApiScope, ApiBaseUrl)

## 5. Offene Entscheidungen (aus den Konzept-Dokus)

1. **Orchestrator-Modell:** Option A (nop-Plugin ruft BC-APIs, empfohlen, kein AL) vs. Option B (BC-AL-Extension ruft nop-REST-API) — siehe `docs/bc-connector-feature-parity.md` §2
2. **Master-Data:** BC = Master (Katalog/Preise/Lager), nop = Auftragsquelle (Paritäts-Default)
3. **v1-Scope:** P0–P2 (Verbindung + Katalog-Sync) empfohlen; Aufträge/Kunden je nach Priorität
4. **Auth-Härtung:** Client-Secret vs. Zertifikat
5. **Multi-Store / Multi-Company** (v1: ein Store)
6. **Webhooks vs. Polling** (Phase P8)
7. Platzhalter-Plugin `Nop.Plugin.Misc.Dynamics365` behalten?

## 6. Referenz-Quellen

- BC Shopify Connector Quellcode (Feature-Vorlage): `/home/boss/bcartifacts-source/onprem/28.4.53241.0/at/Applications/Shopify/app/`
- Plugin-Muster im Repo: `src/Plugins/Nop.Plugin.Misc.Zettle` (API-Client/Sync/Logging), `Nop.Plugin.Misc.Brevo` (Events/Sync-Task), `Nop.Plugin.Misc.Dynamics365` (Stub)
