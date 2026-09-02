# Business Central Connector — Feature Parity with Microsoft's BC Shopify Connector

> Status: v0.1 — derived from the official BC Shopify Connector source code
> Source analyzed: BC OnPrem 28.4.53241.0 · `Applications/Shopify/app` (639 AL files)
> Repo: `nopCommerceMP` · nopCommerce 4.90.7 (net9.0)
> Principle: **everything the BC Shopify Connector can do for Shopify must work for nopCommerce** (nopCommerce replaces Shopify as the store/sales channel).

---

## 1. How the BC Shopify Connector works (the reference)

The Microsoft Shopify connector is an **AL app installed inside Business Central**. Per store it uses a
**"Shpfy Shop" card** (config record) and:

- authenticates against the shop via **OAuth** (`Shpfy Authentication Mgt.`),
- orchestrates all sync from BC side: **BC = master/ERP, Shopify = sales channel**,
- pushes catalog (items → Shopify products incl. variants, images, texts, prices, metafields),
- pulls/pushes **inventory**, **customers**, **B2B companies**, **orders** (Shopify order → BC sales order),
- pushes **fulfillment/invoice** state back to the shop,
- runs on **scheduled jobs (BC job queue) + webhooks** (Shopify → BC for orders/refunds/returns),
- logs everything (`Shpfy Log Entries`, skipped records).

| Module (source folder) | Purpose |
|---|---|
| `Base` | shop card, guided setup wizard, installer/upgrade, background syncs, shop review, communication/filter mgt, tags |
| `Products` | item ↔ product sync both directions, variants, images, collections, sales channels, price calc, status (active/draft/archived), item references |
| `Inventory` | stock to shop, shop locations (fulfillment locations), free inventory, inventory policy |
| `Customers` | customer import/export, mapping strategies, name/contact/county sources, country sync, tax/VAT registration |
| `Companies` | **B2B** company sync (import/export/mapping), contacts, tax id mapping |
| `Order handling` | import shop orders → BC **sales orders**, order mapping, process queue, document links |
| `Payments` | payment transactions, payment terms, "mark as paid", cash roundings, tips, gift-card account |
| `Invoicing` | draft orders, posted invoice sync, update sales invoice |
| `Order Fulfillments` / `Shipping` | export shipments, update sales shipment, fulfillment service (BC as fulfillment provider), shipping methods/charges |
| `Order Returns` / `Refunds` / `Return Refund Processing` | RMA returns, refunds, credit-memo processing strategies |
| `Gift Cards` | sold gift cards |
| `Order Risks` | fraud/risk notes on orders |
| `Translations` | product translations per shop locale |
| `Metafields` | product/customer/company/variant metafields ↔ shop |
| `Catalogs` / `Bulk Operations` | Shopify catalogs/markets/price lists, GraphQL bulk import/export |
| `Webhooks` | manage shop webhook subscriptions, notification handling |
| `Logs` | log entries, skipped records, cleanup |

---

## 2. Architecture: who orchestrates?

The Shopify connector **runs in BC** and calls the **Shopify Admin API**. For nopCommerce there are two ways
to reach feature parity — they differ in *who drives the sync*:

### Option A — nopCommerce plugin orchestrates (RECOMMENDED)

A new plugin **`Nop.Plugin.Misc.BusinessCentral`** runs inside nopCommerce and calls **Business Central
APIs (API v2.0 / OData v4)** outbound (OAuth 2.0 client-credentials).

- BC stays passive API host (only needs an Entra ID app registration + API access).
- nop scheduled task (= BC job queue equivalent) drives catalog/inventory/customer/order sync.
- BC→nop state changes (fulfillment, posted invoices) via **polling** (modified-since markers); BC API v2.0
  **webhook subscriptions** optional later.
- No AL development required. Matches the proven plugin patterns in this repo (Zettle/Brevo).
- The "Shpfy Shop" config record becomes per-store plugin settings + sync-config tables.

### Option B — BC AL extension orchestrates (1:1 port of the Shopify connector)

Build a **new AL app in BC** that calls a **nopCommerce REST API** instead of the Shopify Admin API.

- Requires a full nopCommerce REST surface (products incl. variants/images, inventory, customers, orders,
  fulfillment status, webhook receiver) — the shipped `Nop.Plugin.Misc.WebApi.Frontend` is only a frontend
  for the commercial Web-API product and **not** a basis for this; custom API controllers would be needed.
- Huge additional effort (AL + nop API design + sync-engine rework of ~120 GraphQL call units).

> **Recommendation:** Option A first (delivers ~90 % of the business value, all on the nop stack).
> Option B only if BC users must configure/trigger syncs from inside BC — then expose a focused
> nop REST API (products/inventory/orders/webhooks) and port the Shpfy sync engine.

---

## 3. Config mapping — "Shpfy Shop" card → nopCommerce equivalent

Each field group of the Shopify Shop card becomes part of the nop plugin configuration
(`BusinessCentralSettings` + per-store/connection sync-config tables):

| Shpfy Shop card field(s) | Meaning in connector | nopCommerce equivalent | Status |
|---|---|---|---|
| `Shopify URL`, `Enabled`, `Language Code`, `Currency Code` | shop identity/locale/currency | BC API base URL + environment + company; per-store mapping | Full |
| `Log Enabled`, `Logging Mode` | sync logging | sync-log + skipped-record tables, admin log viewer | Full |
| `Sync Item` (disabled/To Shopify/From Shopify) | item sync direction | item sync direction BC→nop / nop→BC / off (per store) | Full |
| `Item Template Code` | BC defaults for imported items | product default settings (tax category, inventory mode, …) | Partial |
| `Sync Item Images/Extended Text/Attributes/Marketing Text` | which product data is synced | pictures, full/short description, product attributes | Full |
| `UoM as Variant`, `Option Name for UoM`, `Variant Prefix` | UoM becomes a shop variant/option | UoM as product attribute (nop has no native UoM on products) | Partial |
| `SKU Mapping`, `SKU Field Separator` | SKU scheme from BC No. + variant | nop SKU / attribute-combination SKU | Full |
| `Inventory Tracked`, `Default Inventory Policy` | stock tracking + policy (continue/deny) | `ManageInventoryMethod`, backorder/stock settings | Full |
| `Customer Price Group`, `Customer Discount Group` | price/discount groups | nop customer-role tier prices / discounts | Partial |
| `Product Collection` (Tax Group / VAT Prod. Posting Group) | collection source | nop tax category / categories | Partial |
| `Customer Import From Shopify`, `Export Customer To Shopify`, `Auto Create Unknown Customers` | customer sync direction | customer sync BC→nop / nop→BC, auto-create | Full |
| `Customer Mapping Type` (+ Default Customer No.) | how shop customer maps to BC customer (email/phone/bill-to/default) | map by email/company/default (customer) | Full |
| `Name Source`, `Name 2 Source`, `Contact Source`, `County Source` | which BC address fields feed shop customer | address field mapping | Full |
| `Tax Area Source`, `Gen./VAT Bus. Posting Group`, `Tax Liable`, `Prices Including VAT` | BC tax/price handling | tax display, tax category mapping | Partial |
| `Auto Create Orders`, `Auto Release Sales Orders`, `Archive Processed Orders` | sales-order creation behavior | auto-create sales order on order placed/paid | Partial (release is BC-side) |
| `Shopify Order No. on Doc. Line` | reference on document line | BC doc. no. → nop order note/attribute | Full |
| `Payment Terms`, `Cash Roundings/Tip/Gift Card Account`, `Shipping Charges Account` | BC posting accounts/terms | nop payment method/shipping mapping (BC-internal accounts are not nop-relevant) | Partial |
| `Posted Invoice Sync`, `Create Invoices From Orders` | invoice creation and status sync | nop order → invoice in BC; posted invoice → nop payment status | Partial |
| `Fulfillment Service Activated`, `Send Shipping Confirmation` | BC acts as fulfillment service | nop shipment/status + shipping-confirmation email | Partial |
| `Return and Refund Process`, `Return Location`, `Refund Accounts` | RMA handling strategies | nop has no native RMA → refund amount + note / custom handling | Partial |
| `B2B Enabled`, `Company Import/Export`, `Company Mapping Type` | B2B company sync | no B2B-company entity in nop → customer + company attributes | Partial |
| `Product/Customer/Company Metafields To Shopify`, `Order Attributes To Shopify` | custom fields | nop `GenericAttribute` / custom properties / order notes | Partial |
| `Allow Background Syncs` | async background sync | scheduled tasks + event queue | Full |
| `Weight Unit` | units | nop `MeasureWeight` | Full |

---

## 4. Feature-parity matrix (connector modules → nop implementation)

Status: **Full** = natively mapped · **Partial** = mapped with workaround/limitation · **NA** = not applicable (platform concept does not exist)

### 4.1 Catalog — Products (items ↔ nop products)

| Feature | BC object(s) | nop implementation | Status |
|---|---|---|---|
| Item → product push (BC master) | `Shpfy Product Export`, `Shpfy Create Product` | create/update `Product` (by SKU), respect `Published`/deleted | Full |
| Product → item push (nop master) | `Shpfy Product Import`, `Shpfy Update Item` | create/update BC `item` via API | Full |
| Variants (options + variant values) | `Shpfy Variant API`, `Variant Export/Import` | nop has **no native variants** → map to product attributes + **attribute combinations** (own SKU/price/image per combination) | Partial |
| Product/variant images | `Shpfy Product Image Export`, `Variant Image Export`, `Sync Product Image` | nop `Picture` + media; combination images | Full |
| Extended text / marketing text / attributes | `Shpfy Product Export` | full description / short description / attributes | Full |
| Status flow (draft ↔ active ↔ archived) | `Shpfy Create Prod. Status Active/Draft`, `Shpfy To Archived Product`, `Remove Product Action` | `Published` flag + configurable removal action (deactivate/delete/nothing) | Full |
| SKU scheme & item references | `Shpfy SKU Mapping`, `Shpfy Item Reference Mgt.` | nop SKU (combination SKUs) | Full |
| Product collections | `Shpfy Product Collection API` | categories/tax-category mapping | Partial |
| Sales channels / availability | `Shpfy Sales Channel API` | nop store mapping (multi-store) | Partial |
| Price sync (incl. tier prices) | `Shpfy Product Price Calc`, `Sync Catalog Prices`, `Shpfy Update Price Source` | nop `TierPrice` (customer roles) + base price; sync direction configurable | Partial |
| Product translations per locale | `Shpfy Translation Mgt.` | nop `LocalizedProperty` (per language) | Full |

### 4.2 Inventory

| Feature | BC object(s) | nop implementation | Status |
|---|---|---|---|
| Stock push BC → nop | `Shpfy Sync Inventory`, `Shpfy Balance Today`, `Free Inventory` | update `Product.StockQuantity` / combination stock (respect `ManageInventoryMethod`) | Full |
| Locations / location groups | `Shpfy Sync Shop Locations`, `Location Groups` | nop core has no multi-location stock (removed warehouses) → single stock per product, configurable source location | Partial |
| Inventory policy | `Default Inventory Policy` | backorder / stock display settings | Full |

### 4.3 Customers & B2B companies

| Feature | BC object(s) | nop implementation | Status |
|---|---|---|---|
| Customer sync (both directions) | `Shpfy Sync Customers`, `Create/Update Customer` | `Customer` + `Address` create/update (by email) | Full |
| Customer mapping strategies | `Shpfy Customer Mapping` (+ Default Customer) | map by email / company / default customer | Full |
| Name/contact/county sources, countries | `Shpfy Name Source…`, `Shpfy Sync Countries`, `County Code` | address field mapping | Full |
| Tax / VAT registration numbers | `Shpfy Tax Registration No.`, `VAT Registration No.` | customer VAT-number attribute (EU) | Full |
| B2B companies (with contacts/roles/tax ids) | `Shpfy Companies` module | no B2B-company entity → customer flagged as company + `GenericAttribute`s; custom role support | Partial/NA |

### 4.4 Orders, payments, invoicing

| Feature | BC object(s) | nop implementation | Status |
|---|---|---|---|
| Order → BC sales order | `Shpfy Orders`, `Import Order`, `Process Orders` | on order placed/paid event → create BC `salesOrder` + lines (item no., qty, price, VAT) via API; idempotent mapping | Full |
| Order mapping & references | `Shpfy Order Mapping` | mapping table (nop order ↔ BC doc. no.), BC no. stored on nop order | Full |
| Auto create / release / archive | shop-card flags | auto-create toggle; BC release via API where possible; archive = completed nop orders | Partial |
| Cancel order | `Shpfy Order Cancel` | BC sales order cancel → nop order cancel/refund note | Full |
| Payment status ("mark as paid") | `Shpfy Payments`, `Shpfy Mark Order As Paid` | map BC payment to `PaymentStatus` / order note | Full |
| Payment terms & methods | `Shpfy Payment Terms API` | nop payment method mapping | Partial |
| Posted invoice sync | `Shpfy Posted Invoice Export`, `Update Sales Invoice` | BC posted invoice → nop `PaymentStatus.Paid` + invoice no. on order | Full |
| Draft orders / quotes | `Shpfy Draft Orders API` | nop has no draft-order flow (quote plugins exist) | NA/optional |
| Tips / cash roundings / gift-card account | shop-card posting accounts | BC posting internals; nop: gift cards own logic | Partial |

### 4.5 Fulfillment & shipping

| Feature | BC object(s) | nop implementation | Status |
|---|---|---|---|
| Shipment export BC → nop | `Shpfy Export Shipments`, `Shpfy Update Sales Shipment` | create nop `Shipment` + items, mark order shipped | Full |
| Fulfillment-service model | `Shpfy Order Fulfillments`, `Fulfillment Orders API` | order status `Shipped`/shipping-confirmation email | Partial |
| Shipping methods & charges | `Shpfy Shipping Methods`, `Shipping Charges`, `Shipping Events` | shipping-method name mapping; charges in order total | Partial |
| Shipping confirmation | `Send Shipping Confirmation` | nop shipment-sent notification | Full |

### 4.6 Returns, refunds, gift cards, misc

| Feature | BC object(s) | nop implementation | Status |
|---|---|---|---|
| Returns (RMA) | `Shpfy Returns API`, `Return Lines` | **no native RMA** in nop core → return handling via order notes/refund + optional RMA plugin | Partial/NA |
| Refunds + credit memos | `Shpfy Refunds API`, `Refund Process` (default/cr-memo/import-only) | nop partial/full refund amount; BC credit-memo reference in note | Partial |
| Gift cards | `Shpfy Gift Cards` | nop `GiftCard` (code, amount, usage) — different lifecycle, map sold-card accounting | Partial |
| Order risks (fraud) | `Shpfy Order Risks` | nop has no fraud-risk entity → order note from payment provider | NA |
| Metafields | `Shpfy Metafields`, owner types (product/variant/customer/company) | `GenericAttribute` key-value on entities | Partial |
| Translations of products | `Shpfy Translation Api` | nop localized properties | Full |
| Webhook subscriptions | `Shpfy Webhooks Mgt.` | BC API v2.0 webhook subscriptions (optional phase) or polling | Full (optional) |
| Bulk operations | `Shpfy Bulk Operation Mgt.`, GraphQL bulk | batch/chunked sync loops (no GraphQL needed) | Full |
| Logging / skipped records | `Shpfy Log Entries`, `Skipped Record` | sync-log + error/skipped tables with admin UI | Full |
| Document links (open BC doc from order) | `Shpfy Document Links` | link BC sales order/invoice/shipment URL on nop order (order note/custom column) | Full |
| Guided setup / shop review | `Shpfy Guided Experience`, `Shop Review` | setup wizard + config validation (Test Connection) | Full |

---

## 5. nopCommerce platform gaps (honest list)

1. **Product variants** — nop has no native variant entity → product **attributes + attribute combinations** (each combination: own SKU, price, stock, image). Mapping effort is real; UoM-as-variant is the ugliest part.
2. **Multi-location inventory** — nop core has no warehouse/location stock anymore → one stock quantity (+ per combination); BC location must be configurable/aggregated.
3. **B2B companies** — no company entity → company customers + `GenericAttribute` workaround or custom tables.
4. **RMA / returns workflow** — not in core; refunds exist only as money amounts, not as return documents.
5. **Draft orders, order risks, tips, staff roles on the shop side** — platform concepts of Shopify; map to "not applicable" or order notes.
6. **Webhooks into nop** — nop has no generic inbound webhook framework; implement dedicated controllers if needed (or rely on polling).
7. **BC-only concepts** (posting groups, accounts, tax areas, price/discount groups, job queue users, fulfillment service callback URLs) — cannot be configured from nop side; they are BC-side configuration (per parity they belong to the BC company setup anyway).

---

## 6. Suggested delivery phases (per parity area)

| Phase | Scope (feature parity) | Effort |
|---|---|---|
| **P0** | Plugin skeleton: `Nop.Plugin.Misc.BusinessCentral` — plugin.json/csproj, plugin class, defaults, settings, config page, startup/route provider; added to solution | S |
| **P1** | Connection: OAuth 2.0 client-credentials (Entra ID), `Test Connection` + company list, secret encryption, guided setup | S–M |
| **P2** | **Catalog BC → nop**: items → products (create/update, status, images, descriptions, attributes→combinations, SKU scheme), sync log, mapping table, sync task + "Sync now" | M–L |
| **P3** | **Prices & inventory**: tier-price/base-price sync, stock pull BC → nop (+ combination stock), inventory policy mapping | M |
| **P4** | **Customers**: sync both directions, mapping strategies (email/company/default), auto-create, countries | M |
| **P5** | **Orders nop → BC**: sales-order creation (auto/on-demand), lines incl. VAT/shipping, cancel, mapping & idempotency, order attributes/notes | L |
| **P6** | **Fulfillment & invoicing BC → nop**: posted invoices (paid status), shipments → nop shipment + shipped status, shipping-confirmation mails, document links | M |
| **P7** | **Refunds/returns (partial)**, gift cards (partial), translations, metafields → generic attributes, log viewer polish, multi-store/multi-company | L |
| **P8** | **Optional**: nop REST API endpoints for Option B (BC/AL or Power Platform inbound), BC API v2.0 webhook subscriptions, B2B company support | L |

> Direction question per entity (who is master) is a config decision per store — default: **BC = master** for
> catalog/stock (like the Shopify connector), **nop = order source** (like Shopify).

---

## 7. Reference points in the BC source (for implementers)

- BC artifact analyzed: `/home/boss/bcartifacts-source/onprem/28.4.53241.0/at/Applications/Shopify/app/src/…`
- Shop card config: `Base/Tables/ShpfyShop.Table.al` + `Base/Pages/ShpfyShopCard.Page.al`
- Orchestration: `Base/Codeunits/ShpfyBackgroundSyncs.Codeunit.al`, `ShpfyShopMgt.Codeunit.al`
- Catalog: `Products/Codeunits/ShpfyProductExport|Import|SyncProducts|ProductAPI…`, `Products/Codeunits/ShpfyCreateProduct|CreateItem…`
- Orders: `Order handling/Codeunits/ShpfyOrders|ImportOrder|ProcessOrders|OrderMgt…`
- Inventory: `Inventory/Codeunits/ShpfySyncInventory|SyncShopLocations…`
- nop reference implementation patterns: `Nop.Plugin.Misc.Zettle` (API client, sync task, logging), `Nop.Plugin.Misc.Brevo` (event consumer, sync registration), both in `src/Plugins/…`
