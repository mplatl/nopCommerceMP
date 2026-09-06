# Konzept: Verband / Zentrale / Lieferadressen — Login- & Bestellmodell

> Status: **Plan** (nichts implementiert) · Datum: 06.09.2026
> Ziel: Geschäftsmodell „Kunde = Verband, Zentrale = Bill-To, Lieferadressen = eigentliche Nutzer"
> sauber auf nopCommerce + Business Central abbilden, inkl. Login-/Berechtigungs- und Bestelllogik.

---

## 1. Fachliches Modell (Beispiel)

| Begriff | Bedeutung | Abbildung BC | Abbildung nopCommerce |
|---|---|---|---|
| **Verband (Kunde)** | Auftraggeber/Rechnungskunde | **Customer (Bill-to Customer No.)** | nop-Kundenkonto *Verband* (Admin) |
| **Zentrale** | Hauptsitz des Verbands | Bill-to-Kunde = Verband (eine Adresse am Kunden) | Teil des Verbandskontos |
| **Lieferadresse** | eigentlicher Besteller/Lieferort | Ship-to (Adressdaten am Verkaufsbeleg; Referenz „Delivery Address Code") | eigene nop-Kundenkonten (normale Nutzer) *oder* gepflegte Lieferadressen-Katalogeinträge |
| **Admin-User** | verwaltet Verband/Lieferadressen, bestellt für jede Lieferadresse | → Verband | nop-Konto mit Rolle „Verband-Admin" |
| **Normaler User (Lieferadresse)** | bestellt **für seine** Lieferadresse, sieht **nur eigene** Aufträge | → Verband bleibt Bill-To | eigenes nop-Kundenkonto |

**Kernregel:** *Bill-to bleibt immer der Verband (Zentrale); geliefert wird an die gewählte Lieferadresse. Unabhängig vom Login entsteht der Auftrag in BC am selben Bill-to-Kunden.*

---

## 2. Rollen & Sichtbarkeit

| Login | Bestellen für | Sichtbare Aufträge (Shop) | In BC angelegter Beleg |
|---|---|---|---|
| **Admin (Verband)** | beliebige Lieferadresse des Verbands (Auswahl) | alle Aufträge des Verbands (Gruppe über `bcCustomerNo`) | Bill-to = Verband; Ship-to = gewählte Lieferadresse |
| **Normal (Lieferadresse)** | nur seine zugeordnete Lieferadresse (fix, keine Auswahl) | nur seine eigenen Aufträge (nop-Standard je Konto) | Bill-to = Verband; Ship-to = seine Lieferadresse |

Zwei nop-Rollen (Custom), pro Shop zuordenbar:
- `Verband Admin` — Darf Lieferadressen wählen/verwalten, sieht Verbands-Aufträge.
- `Lieferadressen-User` — gebunden an genau eine Lieferadresse, Standard-Sichtbarkeit (nur eigene Bestellungen).

---

## 3. Zuordnung / „welcher Kunde ist das"

Bestehendes Muster wird erweitert statt ersetzt:

- **`bcCustomerNo`** (Kunden-Attribut in nop, je Konto) = **Bill-to = Verband** (Zentrale). Wird weiterhin vom Plugin beim Anlegen gesetzt.
- **Neu: Lieferadressen-Zuordnung pro nop-Konto**: Attribut `bcAddressCode` bzw. Zuordnungstabelle `Login → Delivery Address Code`.
- **Adressstamm** lebt in **BC** (Master) und wird per Plugin an nop geliefert (Liste je Shop), damit Admin bei der Auswahl echte Codes bekommt.

### BC-Datenseite (Erweiterungen im Connector)

1. **`Nop Delivery Address`** (Master, je Shop):
   - Shop Code, **Address Code**, Bezeichnung/Name, Straße/PLZ/Ort/Land, Aktiv
   - `Bill-to Customer No.` (= Verband, dem die Lieferadresse gehört; mehrere Lieferadressen je Verband)
   - nop-seitige Referenz (adress id / key) für Abgleich
2. **`Nop Customer Login`** (bestehend) wird erweitert:
   - `Is Administrator` (Ja/Nein) — Admin-Login des Verbands
   - `Delivery Address Code` (nur bei normalen Nutzern; Admin = leer/alle)
   - (bleibt: Shop, Customer No. = **Bill-to-Verband**, E-Mail, Initial-Passwort, Status, …)
3. Beim **Push** der Logins erhält nop: Konto + Rolle (`Admin`/`User`) + `bcCustomerNo` (Verband) + ggf. `Delivery Address Code`.

### nop-Datenseite (Anpassungen im Shop)

- Rollen: „Verband Admin" / „Lieferadressen-User" (Custom Customer Roles je Shop).
- Kontoattribute: `bcCustomerNo` (bestehend), neu `bcAddressCode` (normaler User) bzw. „ist Admin".
- Lieferadressen-Katalog (für Auswahl im Checkout/Admin): Spiegel des BC-Adressstamms (Liste je Shop).

---

## 4. Login- & Bestellablauf

1. **Login** (nop-Standard, E-Mail/Passwort — jedes Konto ist ein eigenes nop-Konto, **kein** Umbau des Login-Mechanismus nötig).
2. **Admin (Verband):** darf im Checkout die Lieferadresse aus dem Verbandskatalog wählen (oder verwalten). Bestellung läuft auf das Admin-Konto.
3. **Normaler User:** Lieferadresse ist fix (aus `bcAddressCode`), keine Auswahl. Bestellung läuft auf sein Konto.
4. **Bestellung → Plugin-Export** liefert je Order:
   - `customerNo` = Verband (Bill-to, aus `bcCustomerNo`)
   - `addressCode` + Lieferadress-Schnappschuss (gewählte/zugeteilte Lieferadresse)
5. **BC-Import:** legt Verkaufsbeleg an mit
   - **Bill-to Customer = Verband** (Zentrale)
   - **Ship-to = Lieferadresse** (Code + Adressdaten am Beleg; sofern in BC als Ship-to-Adresse gepflegt → Referenz, sonst Adress-Schnappschuss)

→ Damit ist die Kernregel erfüllt: *egal wer sich anmeldet (loginA=Admin oder loginB=Lieferadresse), der Beleg landet beim selben Bill-to-Verband; geliefert wird an die gewählte/zugeteilte Lieferadresse.*

---

## 5. Auftrags-Sichtbarkeit im Shop

- **Normaler User:** nop-Standard — er sieht nur seine eigenen Bestellungen (sein Konto hat nur seine Lieferadresse). Kein zusätzlicher Mechanismus.
- **Admin (Verband):** sieht die Aufträge **aller** Lieferadressen seines Verbands. Umsetzung wie zuvor geplant: „Meine Bestellungen" = Bestellungen der Konten mit derselben `bcCustomerNo` (Gruppe über das Attribut; Attribut bleibt intern, muss nicht sichtbar sein).
- **BC:** Aufträge stehen ohnehin gesammelt am Verband (Bill-to) — Lieferadresse je Beleg.

---

## 6. Abgrenzung / was bewusst NICHT gemacht wird

- Kein „mehrere E-Mails → ein Kundenkonto"-Umbau des nop-Logins (pro Login weiterhin eigenes nop-Konto; „gleiche Aufträge" ergibt sich über Gruppierung bzw. Bill-to).
- Kein nop-internes Adress-„Verbands-UI" über den Standard hinaus (Adressverwaltung bleibt bei BC; nop erhält Katalog/Attribut).

---

## 7. Offene Entscheidungen (für die Umsetzungsplanung)

1. **Adressverwaltung im Checkout:** Admin wählt aus dem Katalog (Code) — oder auch Freitext-Lieferadresse erlaubt?
2. **Lieferadressen-Master:** Pflege in BC (Empfehlung) — Synchronisation „BC → nop Katalog" als eigener Push nötig (ähnlich Produkte).
3. **Ship-to in BC:** eigene Ship-to-Adressen am Verband (Code) vs. Adress-Schnappschuss je Beleg (Empfehlung für Start: Schnappschuss + Code als Referenz).
4. **Admin-Sichtbarkeit Gruppe:** Verbands-Admin sieht auch eigene „administrative" Bestellungen — ja.
5. **Verteilung beim Erstanlegen:** Wie kommen Lieferadresse-Konten (normal users) ins System? Anlage in BC (wie Produkte/Logins) je Verband, dann Push.

---

## 8. Grobe Umsetzungsreihenfolge (wenn freigegeben)

1. **BC:** `Nop Delivery Address`-Master + Felder (`Is Administrator`, `Delivery Address Code`) an `Nop Customer Login` + UI (Verband = Shop-Kunde).
2. **Plugin:** Push Adressstamm (`POST …/delivery-addresses`) + Logins erweitert (Rolle/Adresse/`bcCustomerNo`); Orders-Export liefert `customerNo` + `addressCode` + Adress-Schnappschuss.
3. **nop:** Rollen + Katalogspiegel + (Checkout)-Auswahl für Admin; normale User gebunden an ihre Adresse.
4. **BC-Import:** Verkaufsbeleg Bill-to=Verband, Ship-to=Lieferadresse (Schnappschuss/Referenz).
5. **Admin-Gruppensicht** „Meine Bestellungen" über `bcCustomerNo`.
