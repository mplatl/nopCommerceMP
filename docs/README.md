# nopCommerceMP — nopCommerce ⇄ Business Central Connector

> Dieses Repo basiert auf **nopCommerce 4.90.7** (net9.0) und enthält den kompletten
> **Business-Central-Connector** aus zwei Komponenten:
> 1. **nopCommerce-Plugin** `Nop.Plugin.Misc.BusinessCentral` (läuft im Shop)
> 2. **Business-Central-AL-App** „nopCommerce Connector" (läuft in BC, Container + Cloud-Sandbox)

Der Connector ist am offiziellen **Microsoft Shopify Connector** modelliert
(BC-Quellcode 28.4.53241.0 analysiert, siehe `docs/bc-connector-feature-parity.md`):
**Business Central = Master/ERP** (Katalog, Preise, Lager), **nopCommerce = Sales-Channel/Auftragsquelle**.

---

## 1. Architektur & Datenfluss

```
┌──────────────────────────────┐        ┌─────────────────────────────────────┐
│  Business Central (AL-App)   │        │  nopCommerce (Plugin)               │
│  „nopCommerce Connector"     │        │  Nop.Plugin.Misc.BusinessCentral    │
│                              │        │                                     │
│  • Shop-Karte (Pro Shop)     │  HTTPS │  • REST-Endpoints (X-Api-Key):      │
│  • Produkt-Auswahl/-Status   │───────▶│    GET  /api/bc/health              │
│  • Sync-Engine (ab Iter. B)  │        │    POST /api/bc/products            │
│                              │        │    GET  /api/bc/orders?since=&max=  │
│  BC = Orchestrator/Master    │        │    GET  /api/bc/customers?since=    │
└──────────────────────────────┘        └───────────────┬─────────────────────┘
                                                        │ (optional, P1 outbound)
                                                        ▼
                                   ┌──────────────────────────────────────┐
                                   │ Business Central API v2.0 (Cloud)    │
                                   │ OAuth 2.0 client-credentials (Entra) │
                                   │ z. B. GET /companies (TestConnection)│
                                   └──────────────────────────────────────┘
```

- **BC → nop (Katalog-Export):** Nur explizit ausgewählte Artikel („Nop Product"-Einträge
  je Shop) werden per `POST /api/bc/products` angelegt/aktualisiert. Der nopCommerce-`Sku`
  ist der Mapping-Schlüssel zum BC-Artikelnr. `remove=true` archivert (unpublisht) das Produkt.
- **nop → BC (Aufträge/Kunden-Import):** BC pollt `GET /api/bc/orders|customers?since=…`
  (ISO-8601-Marker) und legt Sales Orders/Kunden an (Iteration B+).
- **Auth:** Plugin-Endpoints prüfen den Header `X-Api-Key` gegen den konfigurierten
  (verschlüsselten) API-Key. Richtung nop → BC läuft über OAuth-Client-Credentials.

> Detaillierte Konzepte: `docs/business-central-plugin-concept.md`,
> Feature-Parität & Mapping: `docs/bc-connector-feature-parity.md`.

---

## 2. Repo-Struktur (relevant)

```
bc-app/nopCommerceConnector/          Business-Central-AL-App „nopCommerce Connector"
  app.json                            App-ID/-Version, ID-Range 62100–62300, Target Cloud
  *.al                               Tabellen, Enum, Seiten, Codeunit (Namespace NopCommerceConnector)
  Translations/*.g.xlf                Übersetzungsdatei (XLIFF)
  .vscode/settings.json               Code-Analyse: CodeCop/PerTenantExtensionCop/UICop
  .alpackages/                        Symbol-Pakete (Platform 28.0 / App 28.4 — NICHT committen, .gitignore)
  nopCommerceConnector.app            Kompilierte App (Build-Artefakt — NICHT committen, .gitignore)
src/Plugins/Nop.Plugin.Misc.BusinessCentral/   nopCommerce-Plugin (nop-Seite)
  BusinessCentralApiController.cs     Inbound-REST-API für die BC-App (X-Api-Key)
  Services/                           BusinessCentralHttpClient/-Service (P1, OAuth → BC-API)
  Domain/Api, Models/Api              DTOs
  Controllers/, Infrastructure/, Views/, Models/   Admin-Config + Routen
dev/                                  Dev-/Build-Skripte
  build-bc-app.sh                     AL-App kompilieren (altool)
  upload-bc-app.sh                    AL-App in Cloud-Sandbox deployen (Automation-API)
  docker-bootstrap.py                 nopCommerce-Erstinstallation/-Verifikation (idempotent)
  test-bc-connection.py               P1 „Test Connection" nop-Plugin → BC-API (End-to-End)
docs/                                 Konzept-, Paritäts- & State-Doku (dieses Readme, …)
```

---

## 3. Voraussetzungen (lokal)

| Komponente | Hinweis |
|---|---|
| Docker + docker compose | nopCommerce-Stack (Web + SQL Server) |
| .NET SDK 9.0.317 | `export PATH="$HOME/.dotnet:$PATH"` (global.json verlangt 9.x) |
| BC-Linux-Container | `MsDyn365Bc.On.Linux`, BC 28.x — siehe `docs/`-Verweis u. Skill bc-linux-container |
| AL-Tool `altool` | VS-Code-AL-Extension `…/ms-dynamics-smb.al-*/bin/linux/altool` (Execute-Bit setzen) |
| Symbol-Pakete | liegen in `bc-app/nopCommerceConnector/.alpackages/` (Platform 28.0.53152.0 / Application 28.4.53241.0) |
| Cloud-Sandbox | Entra-ID-App-Registrierung mit `Automation.ReadWrite.All` (Client-ID/Secret), Environment-Name, Tenant-ID |

---

## 4. Installation — nopCommerce-Plugin

### Plugin-Steckbrief (`Nop.Plugin.Misc.BusinessCentral`)

| Eigenschaft | Wert |
|---|---|
| Plugin-Name (Admin) | „Business Central“ |
| SystemName | `Misc.BusinessCentral` |
| Gruppe / DisplayOrder | `Misc` / 1 |
| Version | 1.00 (unterstützt nopCommerce 4.90) |
| Author | nopCommerceMP |
| Konfigurationsseite | `/Admin/BusinessCentral/Configure` (Menü: Configuration → Local plugins) |

Das Plugin verbindet den Shop mit Business Central in **zwei Richtungen**:

- **Inbound (für die BC-App):** REST-Endpoints `/api/bc/health|products|orders|customers` mit Auth per `X-Api-Key`-Header — das ist die API, die die Business-Central-AL-App „nopCommerce Connector“ aufruft.
- **Outbound (P1):** eigener Zugriff auf die BC-API v2.0 per OAuth 2.0 client-credentials (Entra-ID) — z. B. für „Test Connection“/Unternehmensliste.

API-Key und Client-Secret werden **verschlüsselt** in der DB gespeichert; ein leeres Feld behält den vorhandenen Wert.

### Einstellungen (Config-Seite)

| Feld | Bedeutung |
|---|---|
| Enabled | Verbindung aktiv (Default nach Installation: **aus** — erst nach erfolgreicher Konfiguration aktivieren) |
| UseSandbox | Sandbox- statt Produktions-Umgebung (Default: **an**) |
| TenantId | Microsoft-Entra-ID-Tenant (GUID) der BC-Umgebung |
| EnvironmentName | Name der BC-Umgebung (z. B. `sandbox`, `sandbox29`) |
| ClientId | Anwendungs-ID (client ID) der Entra-ID-App |
| ClientSecret | Client-Secret der App (OAuth client-credentials) |
| ApiKey | **API-Key für die BC-App** (Header `X-Api-Key`) — gleichen Key in der BC-Shop-Karte eintragen |
| CompanyName | BC-Company, mit der synchronisiert wird |
| LogSyncMessages | Sync-/Fehler-Logging (Default: **an**) |
| RequestTimeout | Request-Timeout in Sekunden (Default: 30) |
| Test Connection | prüft OAuth-Verbindung und listet die verfügbaren BC-Company-Namen |

```bash
cd ~/Dokumente/git_private/nopCommerceMP
docker compose up -d --build                # Shop + DB starten
python3 dev/docker-bootstrap.py             # Erstinstallation automatisch (Login, Plugin, Config-Seite)
```

**Plugin bauen (nach Code-Änderungen):**
```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet build src/NopCommerce.sln -v minimal
docker compose up -d --build                # neue DLL ins Image (Container neu bauen)
```

**Konfiguration im Admin** (`http://localhost/Admin` → „Business Central" / `/Admin/BusinessCentral/Configure`):
1. **API-Key** erzeugen und speichern — er autorisiert Aufrufe der BC-App
   (Header `X-Api-Key`), wird verschlüsselt abgelegt.
2. Optional **P1-Verbindung BC-API** (nop → BC): Tenant-ID, Environment-Name,
   Company-Name, Client-ID/-Secret (Entra-ID-App mit API-Zugriff) eintragen →
   „Test Connection" zeigt die verfügbaren Unternehmen.
   Automatisiert: `BC_TEST_*`-Env-Variablen + `python3 dev/test-bc-connection.py`.

**Inbound-REST-Endpoints der BC-App (Public API):**

| Endpoint | Methode | Zweck |
|---|---|---|
| `/api/bc/health` | GET | Health-Check → „Test Connection" in BC |
| `/api/bc/products` | POST | Artikel anlegen/aktualisieren (JSON, `sku` = Mapping-Schlüssel; `remove:true` archivert) |
| `/api/bc/orders` | GET | Neue/geänderte Bestellungen seit `since` (ISO-8601), Paginierung `max` (Default 100, max 500) |
| `/api/bc/customers` | GET | Neue/geänderte Kunden seit `since` |

Alle Endpoints: Auth per `X-Api-Key`-Header, Antworten camelCase-JSON.
Öffentlich erreichbar machen (z. B. Tunnel/Port-Forward) ist nur nötig, wenn die
**Cloud-Sandbox** direkt zugreifen soll — lokal reicht `http://localhost`.

---

## 5. Installation — BC-App „nopCommerce Connector"

### 5.1 Build

```bash
./dev/build-bc-app.sh          # nutzt altool compile gegen .alpackages → bc-app/nopCommerceConnector/nopCommerceConnector.app
```

### 5.2 Lokal (BC-Linux-Container, Empfehlung: immer zuerst hier testen)

Container läuft (Projekt `MsDyn365Bc.On.Linux`, BC 28.x, Dev-Endpoint `http://localhost:7049/BC/dev`,
Auth `BCRUNNER` / `Admin123!`). Publish z. B. per Dev-Endpoint:

```bash
cd bc-app/nopCommerceConnector
curl -sf -u 'BCRUNNER:Admin123!' -X PUT 'http://localhost:7049/BC/dev/apps?SchemaUpdateMode=ForceSync' \
  -H 'Content-Type: application/octet-stream' --data-binary @nopCommerceConnector.app -w 'HTTP %{http_code}\n'
# Verifikation: installierte Apps auflisten
curl -sf -u 'BCRUNNER:Admin123!' 'http://localhost:7049/BC/dev/apps' | python3 -m json.tool | head
```

Alternativ in VS Code über die AL-Erweiterung („Publish" auf den Dev-Endpoint).

### 5.3 Cloud-Sandbox (per Automation-API)

Voraussetzung: Entra-ID-App mit `Automation.ReadWrite.All` + **einmalige Freigabe**
(Admin-Consent/App-Installation in der Ziel-Umgebung — nach Fehlschlag nicht blind
wiederholen, lokale Validierung bevorzugen).

```bash
BC_TENANT_ID=… BC_ENV=sandbox29 \
BC_CLIENT_ID=… BC_CLIENT_SECRET=… \
./dev/upload-bc-app.sh bc-app/nopCommerceConnector/nopCommerceConnector.app "CRONUS AT"
```

Das Skript: Token holen → `extensionUpload` anlegen → `.app`-Stream hochladen →
`Microsoft.NAV.upload` auslösen → Deployment-Status pollen.
Anschließend App unter „Extension Management" prüfen.

> Hinweis: Aus der Cloud-Sandbox ist `http://localhost` des Shops **nicht** erreichbar —
> echte End-to-End-Tests brauchen eine öffentlich erreichbare nopCommerce-URL
> (Tunnel/Port-Forward/Server-Deployment).

---

## 6. Bedienung in Business Central

1. Suche nach **„nopCommerce Connection"** (Seite `Nop Commerce Setup`, Karte).
2. **Shop anlegen:** Code, Beschreibung, `Enabled`, nopCommerce-URL (öffentlich erreichbar
   für Cloud) und API-Key des nop-Plugins.
3. **„Test Connection"** prüft Erreichbarkeit + API-Key gegen `/api/bc/health`
   (aktuell Placeholder — echte Implementierung = Iteration B).
4. **„Products"** öffnet die Produktliste des Shops (Seite `Nop Commerce Products`):
   Nur Artikel, die hier als Eintrag existieren, werden nach nopCommerce exportiert —
   nie der komplette Katalog.
5. **Status:** `Draft` (noch nicht exportiert) → `Active` (exportiert & synchron) →
   `Archived` (aus nopCommerce entfernt).

---

## 7. Entwicklungsstand & nächste Schritte

| Stand | Inhalt |
|---|---|
| ✅ Iteration A | AL-App-Grundgerüst: Shop-Tabelle, Produkt-Auswahl/-Status, Setup-/Produkt-Seiten, Übersetzungen; kompiliert gegen Platform 28.0; läuft im lokalen Container; in Cloud-Sandbox installiert |
| ✅ nop-Plugin | P1-Verbindung BC-API (OAuth) live verifiziert; Inbound-REST-Endpoints health/products/orders/customers implementiert |
| 🔜 Iteration B | AL-seitig: echte HTTP-Aufrufe — `TestConnection` gegen `/api/bc/health`, Produkt-Push (`POST products`, Status-Flow), dann Order-/Customer-Import mit Mapping; danach Job Queue, Sync-Log, Versions-Bumps |

**AL-Regeln (Lessons — nie wieder verletzen!):**
1. Neue GUID je App in `app.json` — nie kopieren.
2. Objekt-ID-Range **62100–62300** (nicht 50000er — Kollision mit GLAccount Workflow 50100–50109).
3. `ApplicationArea = All;` auf Seitenebene; Cops (CodeCop/PerTenantExtensionCop/UICop) aktiviert.
4. Erst lokal publizieren/validieren (Container), dann Cloud; Automation-Upload nicht mit Wiederholungen verkleben.

Ausführlicher Stand: `docs/DEVELOPMENT-STATE.md` · Roadmap/Parität: `docs/bc-connector-feature-parity.md` · Konzept: `docs/business-central-plugin-concept.md`

---

## 8. Umgebung & Zugangsdaten (nur lokale Entwicklung!)

- Shop: http://localhost · Admin: http://localhost/Admin
- **Admin:** `admin@yourStore.com` / `NopMP!2025#`
- **SQL Server:** Container `nopcommerce_mssql_server`, `sa` / `nopCommerce_db_password`, DB `nopCommerce`
- **BC-Container:** Dev `http://localhost:7049/BC/dev` · OData `http://localhost:7048/BC/ODataV4` · API `http://localhost:7052/BC/api/v2.0` — Auth `BCRUNNER` / `Admin123!`
- Cloud-Zugangsdaten (Sandbox/Entra-ID) **nur über Umgebungsvariablen** — nie ins Repo!

## 9. Wiederaufnahme (nach Reboot / neuer Shell)

```bash
cd ~/Dokumente/git_private/nopCommerceMP
docker compose up -d --build          # Shop (nopCommerce) starten
python3 dev/docker-bootstrap.py       # Login + Plugin + Config-Seite verifizieren
# BC-Container (falls benötigt):
cd ~/Dokumente/MsDyn365Bc.On.Linux && BC_VERSION=28.1 docker compose up -d --wait
```
