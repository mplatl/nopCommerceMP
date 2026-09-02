# Concept: Business Central Connection Plugin for nopCommerce

> Status: Concept v0.1 — for review
> Repo: `nopCommerceMP` · nopCommerce 4.90.7 (net9.0)
> Goal: Connect the nopCommerce store to Microsoft Dynamics 365 **Business Central** (BC) via a custom nopCommerce plugin ("nop plugin for the BC APIs").
> **Functional benchmark: full parity with Microsoft's official BC Shopify Connector** — everything it can do with a Shopify store must work with nopCommerce. See [`bc-connector-feature-parity.md`](bc-connector-feature-parity.md).

---

## 1. What was analyzed

### 1.1 The application (nopCommerceMP)

- Stock **nopCommerce 4.90.7** source tree (single commit `Import nopCommerce 4.90.7 source code`, private repo `mplatl/nopCommerceMP`), no customizations yet.
- Solution `src/NopCommerce.sln` with 27 plugin projects; layers:
  - `src/Libraries` → `Nop.Core`, `Nop.Data`, `Nop.Services`
  - `src/Presentation` → `Nop.Web`, `Nop.Web.Framework` (Mvc/Razor, routing, admin conventions)
  - `src/Plugins` → 27 shipped plugins
  - `src/Tests`
- Runtime: .NET 9, MS SQL (docker-compose; MySQL/PostgreSQL compose files present), runs on Linux via `Dockerfile`.

### 1.2 How nopCommerce plugins work (reference pattern)

The **PayPal Zettle** plugin (`src/Plugins/Nop.Plugin.Misc.Zettle`) is the best in-repo template for an external API integration (OAuth, REST client, scheduled sync, webhooks). Pattern used by every "Misc"-group plugin:

| Concern | Mechanism (verified in repo) |
|---|---|
| Plugin identity | `plugin.json` (`Group: "Misc"`, `SystemName`, `Version`, `SupportedVersions`) + `.csproj` in the solution |
| Lifecycle | `BasePlugin` subclass → override `GetConfigurationPageUrl()`, `InstallAsync()`, `UninstallAsync()` |
| Admin config page | Named route via `Infrastructure/RouteProvider.cs : IRouteProvider` → `MapControllerRoute("Plugin.Misc.X.Configure", "Admin/X/Configure", …)` (admin controller, `[AuthorizeAdmin]` / antiforgery) |
| Settings | POCO `…Settings : ISettings`, saved via `ISettingService` (`SaveSettingAsync/GetSettingsAsync`) |
| Constants | `…Defaults.cs`: SystemName, route names, webhook route, sync-task tuple `(Name, Type, Period)` |
| DI / HttpClient | `Infrastructure/NopStartup.cs : INopStartup` → `services.AddHttpClient<…HttpClient>().WithProxy()` + scoped services |
| Periodic sync | `…SyncTask : IScheduleTask` (type-name registered via `ScheduleTask` in DB, e.g. `Nop.Plugin.Misc.Zettle.Services.ZettleSyncTask`, 28800 s) |
| Real-time hooks | `Services/EventConsumer.cs : IConsumer<…>` |
| Public callbacks | public controller + `WebhookRouteName` |
| Localization | resource keys added on install (`AddOrUpdateLocaleResourceAsync`) |

### 1.3 The shipped "Dynamics365" plugin is NOT a BC connector

`src/Plugins/Nop.Plugin.Misc.Dynamics365` contains only a stub (plugin class, defaults, one event consumer, a Configure view) that markets the commercial nopCommerce Dynamics 365 connector. **There is no Business Central code in this repo** — a real connector must be built as a new plugin.

### 1.4 Functional benchmark: the official BC Shopify Connector

The customer requirement is **feature parity with Microsoft's official Business Central Shopify Connector** — everything that connector can do with a Shopify store must work with the nopCommerce store (nopCommerce = shop / sales channel). The connector's full feature inventory was derived from its AL source code (BC OnPrem 28.4.53241.0, `Applications/Shopify/app`, 639 AL files; module areas: Base/Setup, Products, Inventory, Customers, Companies (B2B), Order handling, Payments, Invoicing, Fulfillment & Shipping, Returns/Refunds, Gift Cards, Translations, Metafields, Webhooks, Logs) and is mapped 1:1 to nopCommerce in [`bc-connector-feature-parity.md`](bc-connector-feature-parity.md).

Key consequences for this design:
- BC is the **ERP/master**, nopCommerce is the **sales channel** (exactly the role Shopify plays for the connector).
- Feature areas and nopCommerce platform gaps (variants → attribute combinations, no multi-location stock, no native RMA/B2B companies) are listed there; every gap has a defined workaround or a "not applicable" verdict.
- The orchestration model (recommended: the nop plugin calls BC APIs outbound so BC stays a passive API host) is discussed in section 2 and in the parity document §2.

---

## 2. Integration architecture (recommended)

```
┌──────────────────────────┐          OAuth 2.0 client-credentials          ┌─────────────────────────────┐
│  nopCommerce (this repo) │  ───────────────────────────────────────────▶  │   Microsoft Entra ID (AAD)  │
│                          │   POST /{tenant}/oauth2/v2.0/token            │   App registration (client) │
│  New plugin              │  ◀───────────────────────────────────────────  └──────────────┬──────────────┘
│  Nop.Plugin.Misc.        │                                                               │ access token
│  BusinessCentral         │                                                               ▼
│                          │   HTTPS (Bearer)                                        ┌─────────────────────────┐
│  ┌────────────────────┐  │   GET/POST/PATCH api/v2.0 …                            │  Business Central       │
│  │ SyncTask (timer)   │──▶──────────────────────────────────────────────────────▶  │  environment + company  │
│  └────────────────────┘  │                                                        └─────────────────────────┘
└──────────────────────────┘
```

- **Direction:** the nopCommerce plugin *calls out* to BC REST APIs (outbound HTTPS only). BC never needs inbound access → simple firewall/DMZ story.
- **Auth:** OAuth 2.0 **client-credentials** (server-to-server, no user interaction) so background sync tasks work unattended. Optional phase 2: BC API v2.0 **webhook subscriptions** (BC pushes change notifications to a public nop endpoint) or nop-side REST exposure (the repo's `Nop.Plugin.Misc.WebApi.Frontend` is only a frontend shell for the commercial Web-API product — real inbound endpoints would need custom controllers) if BC/Power Automate must trigger/pull.

### 2.1 Why a plugin (not core modifications)

- nopCommerce is designed for pluggable extensions; plugins isolate version-specific integration, survive core upgrades, and can be toggled in the admin.
- Keeps the fork clean → future upstream merges stay easy.

---

## 3. Business Central side — the API surface

BC exposes two HTTP flavours; **API v2.0 (JSON/REST) is preferred** for a new plugin:

| Base URL (examples) |
|---|
| API v2.0:  `https://api.businesscentral.dynamics.com/v2.0/{tenant-id}/{environment}/api/v2.0/companies({company-id})/…` |
| ODataV4:   `https://api.businesscentral.dynamics.com/v2.0/{tenant-id}/{environment}/ODataV4/Company('{name}')/…` |

Relevant entities for an e-commerce ↔ ERP sync (subset, expandable):

| Entity | Typical use in sync |
|---|---|
| `companies` | list available companies (default-company setting / test-connection) |
| `items` / `itemCategories` / `unitOfMeasure` | product master data |
| `itemAvailability` / item ledger | stock levels (pull to nop) |
| `customers` | customer master (BC side, or create on demand) |
| `salesOrders` + `salesOrderLines` | push nop orders to BC |
| `postedSalesInvoices`, `salesShipments` | pull fulfillment/invoice state → update nop order |
| `currencies`, `paymentTerms`, `shipmentMethods`, `vat` codes | mapping/reference data |

Platform notes:
- Pagination: `@odata.nextLink` / max page size (API v2.0 default 20, max 2000) → use `$top=2000` + nextLink loop.
- Tokens: `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token`, scope `https://api.businesscentral.dynamics.com/.default`; cache until near-expiry.
- Sandbox vs. production environment URL differ → make environment a setting.

---

## 4. Plugin design — `Nop.Plugin.Misc.BusinessCentral`

### 4.1 Project layout (mirrors Zettle/Brevo)

```
src/Plugins/Nop.Plugin.Misc.BusinessCentral/
├── plugin.json                      # Group "Misc", SystemName "Misc.BusinessCentral", Version 1.00, SupportedVersions ["4.90"]
├── Nop.Plugin.Misc.BusinessCentral.csproj
├── BusinessCentralPlugin.cs         # BasePlugin/IMiscPlugin: config URL, Install/Uninstall (settings, sync task, locale res.)
├── BusinessCentralDefaults.cs       # SystemName, config/webhook route names, sync-task tuple, API URLs, page size, timeouts
├── BusinessCentralSettings.cs       # ISettings (see 4.3)
├── Infrastructure/
│   ├── NopStartup.cs                # AddHttpClient<BusinessCentralHttpClient>().WithProxy(); scoped services + token cache
│   └── RouteProvider.cs             # named admin route + (phase 2) webhook route
├── Controllers/
│   └── BusinessCentralAdminController.cs   # Configure, Save, TestConnection, SyncNow, SyncLog (admin area, authorized)
├── Models/
│   ├── ConfigurationModel.cs        # + record mapping to/from settings
│   └── Validators/ConfigurationValidator.cs
├── Services/
│   ├── BusinessCentralHttpClient.cs # token acquisition + typed client helpers (GET/POST/PATCH, pagination)
│   ├── BusinessCentralService.cs    # orchestration: test-connection, push/pull per entity, mapping
│   ├── BusinessCentralSyncTask.cs   # IScheduleTask → periodic sync
│   ├── BusinessCentralRecordService.cs  # sync records / id-mapping / history / error log (own tables)
│   └── EventConsumer.cs             # (optional) queue products/orders for next sync run
├── Domain/
│   ├── Api/                         # DTOs: OAuthToken, Company, Item, Customer, SalesOrder(+Line), Availability, Invoice…
│   └── Entities/                    # own tables: SyncMapping, SyncRecord / SyncLogEntry (BaseEntity)
├── Data/                            # entity mappings (Nop.Data auto-creates plugin tables)
├── Views/Configure.cshtml (+ _ViewImports.cshtml)   # admin config UI
└── logo.png
```

### 4.2 Core services

1. **BusinessCentralHttpClient** — acquires/caches the Bearer token (client credentials, MSAL or manual HTTP), exposes typed `GetAsync<T>`, `PostAsync`, `PatchAsync`, handles `@odata.nextLink` pagination, `409`/`400` BC business errors, request timeout.
2. **BusinessCentralService** — pure orchestration + entity mapping (no EF writes directly): `TestConnectionAsync()`, `SyncItemsAsync(direction)`, `SyncInventoryAsync()`, `CreateSalesOrderAsync(order)`, `SyncOrderStatusAsync()`, `SyncCustomersAsync()`.
3. **BusinessCentralRecordService** — persists mapping (nop entity ↔ BC id/number) and a sync log (last attempt, result, payload error). Own tables via EF (pattern: `BaseEntity` + mapping config; nopCommerce auto-includes plugin schemas) → survives restarts, enables resync + audit.
4. **BusinessCentralSyncTask** — periodic incremental sync (registered on install like Zettle: name/type/seconds), enabled/disabled in admin.

### 4.3 Configuration page (`BusinessCentralSettings`)

| Setting | Purpose |
|---|---|
| Tenant ID / Environment name / (Environment type: sandbox\|production) | API base URL |
| Client ID / Client Secret (**encrypted** via nop `IEncryptionService`, or certificate thumbprint) | OAuth app-only auth |
| Default BC company | scope for API calls / test connection |
| Sync toggles | items (nop→BC), inventory (BC→nop), customers, prices, orders nop→BC, invoices BC→nop, auto-create customers |
| SKU/number-series handling, tax/mapping options | mapping control |
| Sync interval (s) + "Sync now" button | operations |
| Sync log viewer | transparency & troubleshooting |

Admin UI: standard nop pattern — Settings page with model binding, save → `ISettingService`, plus action buttons wired to controller methods (like Zettle's "disconnect"/Brevo's account info).

### 4.4 Sync scenarios & mapping (default direction)

Decide per entity where master data lives. Typical retail setup: **BC = master (ERP), nop = sales channel**.

| Scenario | nop entity | BC entity | Key/mapping | Default direction | Notes |
|---|---|---|---|---|---|
| Products | `Product` | `item` (no., displayName, unitPrice, vat, itemCategory) | SKU ↔ Item No. | **BC → nop** (create/update) or nop → BC | incremental via modified-on; deactivate instead of delete |
| Stock | `Product.StockQuantity` / manage-inventory methods | `itemAvailability` / item ledger | SKU | **BC → nop** | respect nop stock/backorder settings; log changes |
| Customers | `Customer` | `customer` (no., name, address, vat) | email/number | nop → BC (create if missing) or BC → nop | optional phase; needed as sales-order header context |
| Orders | `Order` (placed/paid event) | `salesOrder` + lines (item no., qty, unit price, vat %, shipment/due date) | nop order no. ↔ BC doc. no. | **nop → BC** | idempotent (mapping check), cancel → BC doc. state |
| Fulfillment/Invoices | `Order` (shipped/completed) | `postedSalesInvoice` / shipment | BC doc. no. | **BC → nop** | map invoice no. + shipment to nop order |
| Prices | tier prices | sales prices / unitPrice | item no. | BC → nop | optional, careful with overrides |

**Idempotency/conflict rules:** every entity gets a mapping row before first push; pushes check `if (mapping exists) PATCH else POST`; on BC business-error → log + retry with backoff, never delete nop data automatically. A "sync window/last-synced-utc" marker per entity drives incremental runs.

**Order handling detail:** BC sales orders require a customer number → default: auto-create/map nop customer by e-mail (configurable) or map all web orders to a configured "web shop customer" (fast start). Tax: map nop tax class ↔ BC VAT product posting group / vat code (configurable table); currency assumed EUR per store; BC `paymentTerms`/`shipmentMethods` mapped from config defaults per store.

### 4.5 Trigger model

- **Primary:** periodic `BusinessCentralSyncTask` (e.g. every 5–15 min; configurable). Simple, robust, works without inbound access, naturally batches.
- **Optional (phase 2):**
  - event-driven queue (`EventConsumer` marks records dirty; next run only syncs dirty) for near-real-time pushes,
  - BC API v2.0 webhook subscriptions (BC → nop public endpoint) for inventory/customer changes,
  - nop REST exposure if BC or Power Automate must pull order data on demand — note: the repo's `Nop.Plugin.Misc.WebApi.Frontend` is only a frontend for the commercial Web-API product; real inbound endpoints would be custom controllers (Option B in the parity doc).

### 4.6 Business Central / Azure prerequisites (checklist for the customer tenant)

- [ ] BC environment (sandbox for dev; production later) incl. company name(s), API access enabled ("Allow OData/AAD" — app-only via AAD is standard)
- [ ] Microsoft Entra ID app registration in the same tenant as BC
  - [ ] client credentials (secret or, better, certificate)
  - [ ] API permission: Dynamics 365 Business Central → application permission (e.g. `API.ReadWrite.All`), **admin consent granted**
- [ ] Confirm token audience/scope `https://api.businesscentral.dynamics.com/.default` works with a manual token test
- [ ] Decide master-data ownership per entity (4.4) → drives mapping implementation

---

## 5. Implementation roadmap

| Phase | Scope (feature parity, see `bc-connector-feature-parity.md` §6) | Effort |
|---|---|---|
| **P0 — Skeleton** | `plugin.json` + csproj, plugin class, defaults, settings, config page, startup/route provider; project added to `NopCommerce.sln` | S |
| **P1 — Connection** | OAuth 2.0 client-credentials (Entra ID), `TestConnectionAsync()` + company list, secret encryption, guided setup | S–M |
| **P2 — Catalog (BC → nop)** | items → products (create/update, status/archive action, images, extended/marketing text, attributes → combinations, SKU scheme), mapping + log tables, sync task, "Sync now" | M–L |
| **P3 — Prices & inventory** | tier prices / base price, stock pull BC → nop (+ combination stock), inventory-policy mapping | M |
| **P4 — Customers** | customer sync both directions, mapping strategies (email/company/default), auto-create, countries | M |
| **P5 — Orders (nop → BC)** | sales-order creation incl. lines/VAT/shipping, cancel, idempotent mapping, order attributes/notes | L |
| **P6 — Fulfillment & invoicing (BC → nop)** | posted invoices → paid status, shipments → nop shipment/shipped, shipping-confirmation mails, document links | M |
| **P7 — Hardening & extras** | refunds/returns (partial), gift cards, translations, metafields → generic attributes, log viewer, multi-store/multi-company, incremental markers, concurrency lock (web-farm safe) | L |
| **P8 — Optional (advanced)** | nop REST endpoints (Option B), BC API v2.0 webhook subscriptions, B2B companies | L |

Foundation pieces to reuse from repo: `IScheduleTask`/`ScheduleTask` registration (Zettle/Brevo), `INopStartup` HttpClient registration with `WithProxy()`, `IRouteProvider` named routes, `IEncryptionService`, admin settings scaffolding (`Nop.Plugin.Misc.Zettle` + `Nop.Plugin.Misc.Brevo` as reference implementations), entity/mapping for own tables (e.g. `Nop.Plugin.Misc.Zettle` record service & `Avalara` data layer patterns).

---

## 6. Open decisions (need product input)

1. **Orchestration model** (parity doc §2): Option A — nop plugin calls BC APIs outbound (recommended; no AL work) vs. Option B — BC AL extension calls a new nopCommerce REST API (1:1 port of the Shopify connector).
2. **Master-data ownership** per entity — parity default: BC = master (catalog/prices/stock), nop = order source.
3. **v1 feature scope & order** — recommend P0–P2 (connection + catalog) first; confirm which Shopify-connector areas are business-critical for launch (orders/customers?).
4. **Auth hardening:** client secret vs. certificate; which BC environment/tenant is the target (sandbox available?).
5. **Multi-store / multi-company:** nop multi-store → per-store connection settings and company mapping (v1: one store).
6. **Webhook vs. polling** appetite for P8 (BC webhooks need a public callback URL + admin consent).
7. Keep the placeholder `Nop.Plugin.Misc.Dynamics365` untouched next to the new plugin (yes/no).

---

## 7. Risks & notes

- BC **API v2.0** differs between environments (sandbox vs prod URL); keep base-URL construction configurable and versioned.
- Rate limits / long-running requests → timeouts, page size, retry with exponential backoff, single-flight sync (no overlapping task runs, esp. web farms).
- OData/JSON field naming (camelCase in API v2.0), number formats, BC business validation errors must surface readable in the sync log.
- Never hard-delete in sync; use deactivation/flags (both sides) and keep mapping history.
- Localization keys `Plugins.Misc.BusinessCentral.*` in `en`/`de` (project convention: UI text via resources — see `dev-english` skill; code in English, UI via resx).
