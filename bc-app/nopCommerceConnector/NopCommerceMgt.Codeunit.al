namespace NopCommerceConnector;

/// <summary>
/// Central management codeunit for the nopCommerce integration (mirrors the Microsoft Shopify "Mgt." codeunits).
/// Business Central is the orchestrator/master: it calls the plugin API of the shops (pull and push);
/// nopCommerce only answers REST calls (X-Api-Key) and never initiates requests.
/// Implemented: connection test (health), language pull per shop ("Nop Language")
/// and the product push per shop (POST /api/bc/products; catalog export of the selected
/// "Nop Product" rows incl. the remove/archive flow).
/// Open: order/customer import (GET /api/bc/orders|customers) and the numeric fields of the
/// product push (price/stock - requires culture-safe decimal serialization).
/// </summary>
codeunit 62100 "Nop Commerce Mgt."
{
    /// <summary>
    /// Verifies the configured nopCommerce connection of a shop by calling the plugin health endpoint.
    /// </summary>
    /// <param name="Shop">The shop to test.</param>
    internal procedure TestConnection(Shop: Record "Nop Commerce Shop")
    var
        NopHttp: Codeunit "Nop Commerce Http";
        ResponseText: Text;
        NopTestOkMsg: Label 'The connection to the shop "%1" is working. The nopCommerce plugin responded: %2';
        NopTestFailMsg: Label 'The connection to the shop "%1" failed. Response: %2';
    begin
        Shop.ValidateSetup();
        if NopHttp.Get(Shop, 'api/bc/health', ResponseText) then
            Message(NopTestOkMsg, Shop.Code, CopyStr(ResponseText, 1, 150))
        else
            Error(NopTestFailMsg, Shop.Code, CopyStr(ResponseText, 1, 150));
    end;

    /// <summary>
    /// Pulls the languages of a shop from the nopCommerce plugin (GET /api/bc/languages) and
    /// updates the per-shop "Nop Language" whitelist (name, culture, published, display order).
    /// Existing "Is Default" flags are kept; a language that was never flagged stays untouched.
    /// </summary>
    /// <param name="Shop">The shop to synchronize.</param>
    internal procedure SyncLanguages(Shop: Record "Nop Commerce Shop")
    var
        NopHttp: Codeunit "Nop Commerce Http";
        NopLanguage: Record "Nop Language";
        DefaultLanguage: Record "Nop Language";
        ResponseText: Text;
        JResponse: JsonToken;
        JLanguages: JsonToken;
        JArray: JsonArray;
        JLanguage: JsonToken;
        JId: JsonToken;
        JValue: JsonToken;
        LanguageId: Integer;
        Name: Text;
        Culture: Code[20];
        SeoCode: Code[20];
        Rtl: Boolean;
        Published: Boolean;
        DisplayOrder: Integer;
        Added: Integer;
        Updated: Integer;
        SyncedMsg: Label 'Languages of the shop "%1" synchronized: %2 added, %3 updated.';
        SyncFailMsg: Label 'The languages of the shop "%1" could not be synchronized. %2';
    begin
        Shop.ValidateSetup();
        Added := 0;
        Updated := 0;

        if not NopHttp.Get(Shop, 'api/bc/languages', ResponseText) then
            Error(SyncFailMsg, Shop.Code, CopyStr(ResponseText, 1, 200));

        if not JResponse.ReadFrom(ResponseText) then
            Error(SyncFailMsg, Shop.Code, 'The nopCommerce response could not be parsed as JSON.');
        if not JResponse.SelectToken('$.languages', JLanguages) then
            Error(SyncFailMsg, Shop.Code, 'The nopCommerce response does not contain the expected "languages" array.');
        if not TryGetArray(JLanguages, JArray) then
            Error(SyncFailMsg, Shop.Code, 'The nopCommerce "languages" element is not an array.');

        foreach JLanguage in JArray do begin
            Clear(Name);
            Clear(Culture);
            Clear(SeoCode);
            Rtl := false;
            Published := false;
            DisplayOrder := 0;

            if not TryGetInt(JLanguage, '$.id', LanguageId) then
                Error(SyncFailMsg, Shop.Code, 'A language record is missing the "id".');
            if not TryGetText(JLanguage, '$.name', Name) then
                Error(SyncFailMsg, Shop.Code, 'A language record is missing the "name".');

            TryGetCode(JLanguage, '$.languageCulture', Culture);
            TryGetCode(JLanguage, '$.uniqueSeoCode', SeoCode);
            TryGetBool(JLanguage, '$.rtl', Rtl);
            TryGetBool(JLanguage, '$.published', Published);
            TryGetInt(JLanguage, '$.displayOrder', DisplayOrder);

            NopLanguage.SetRange("Shop Code", Shop.Code);
            NopLanguage.SetRange("Language ID", LanguageId);
            if NopLanguage.FindFirst() then begin
                NopLanguage.Name := Name;
                NopLanguage."Language Culture" := Culture;
                NopLanguage."Unique SEO Code" := SeoCode;
                NopLanguage.RTL := Rtl;
                NopLanguage.Published := Published;
                NopLanguage."Display Order" := DisplayOrder;
                NopLanguage."Synchronized Date" := CurrentDateTime();
                NopLanguage.Modify();
                Updated := Updated + 1;
            end else begin
                NopLanguage.Init();
                NopLanguage."Shop Code" := Shop.Code;
                NopLanguage."Language ID" := LanguageId;
                NopLanguage.Name := Name;
                NopLanguage."Language Culture" := Culture;
                NopLanguage."Unique SEO Code" := SeoCode;
                NopLanguage.RTL := Rtl;
                NopLanguage.Published := Published;
                NopLanguage."Display Order" := DisplayOrder;
                NopLanguage."Synchronized Date" := CurrentDateTime();
                NopLanguage.Insert();
                Added := Added + 1;

                //first language of a shop becomes the default language (if none exists yet)
                DefaultLanguage.SetRange("Shop Code", Shop.Code);
                DefaultLanguage.SetRange("Is Default", true);
                if not DefaultLanguage.FindFirst() then begin
                    NopLanguage."Is Default" := true;
                    NopLanguage.Modify();
                end;
            end;
        end;

        Message(SyncedMsg, Shop.Code, Added, Updated);
    end;

    /// <summary>
    /// Pushes the selected products of a shop to nopCommerce (POST /api/bc/products).
    /// Rows with status Draft/Active are created/updated (published); rows with status
    /// Archived are removed (remove=true). Successful rows become Active and store the
    /// nopCommerce product id; failed rows keep their status and get a sync error.
    /// </summary>
    /// <param name="Shop">The shop whose store products are exported.</param>
    internal procedure PushProducts(Shop: Record "Nop Commerce Shop")
    var
        NopProduct: Record "Nop Product";
        Pushed: Integer;
        Failed: Integer;
        PushMsg: Label 'Products of the shop "%1" pushed: %2 successful, %3 failed.';
    begin
        Shop.ValidateSetup();
        Pushed := 0;
        Failed := 0;

        NopProduct.SetRange("Shop Code", Shop.Code);
        if NopProduct.FindSet() then
            repeat
                if not PushProduct(NopProduct, Shop, Pushed, Failed) then begin
                    NopProduct."Last Sync Error" := 'Push skipped (product has no item number).';
                    NopProduct.Modify();
                    Failed := Failed + 1;
                end;
            until NopProduct.Next() = 0;

        Message(PushMsg, Shop.Code, Pushed, Failed);
    end;

    /// <summary>
    /// Pushes a single selected product row to nopCommerce and updates the row.
    /// </summary>
    /// <returns>False if the row could not be processed (no item number).</returns>
    local procedure PushProduct(NopProduct: Record "Nop Product"; Shop: Record "Nop Commerce Shop"; var Pushed: Integer; var Failed: Integer): Boolean
    var
        NopHttp: Codeunit "Nop Commerce Http";
        ResponseText: Text;
        JResponse: JsonToken;
        JToken: JsonToken;
        Payload: Text;
        ProductId: Integer;
    begin
        if NopProduct."Item No." = '' then
            exit(false);

        if NopProduct.Status = "Nop Product Status"::Archived then
            Payload := '{"sku":"' + EscapeJson(NopProduct."Item No.") + '","remove":true}'
        else
            Payload := '{"sku":"' + EscapeJson(NopProduct."Item No.") + '","name":"' + EscapeJson(NopProduct.Description) + '","published":true}';

        if not NopHttp.Post(Shop, 'api/bc/products', Payload, ResponseText) then begin
            NopProduct."Last Sync Error" := CopyStr(ResponseText, 1, 250);
            NopProduct.Modify();
            Failed := Failed + 1;
            exit(true);
        end;

        ProductId := 0;
        if JResponse.ReadFrom(ResponseText) then
            if JResponse.SelectToken('$.productId', JToken) and JToken.IsValue and not JToken.AsValue().IsNull then
                ProductId := JToken.AsValue().AsInteger();

        NopProduct."Last Sync Error" := '';
        if ProductId <> 0 then
            NopProduct."Nop Product Id" := ProductId;
        NopProduct."Synchronized Date" := CurrentDateTime();
        if NopProduct.Status <> "Nop Product Status"::Archived then
            NopProduct.Status := "Nop Product Status"::Active;
        NopProduct.Modify();

        Pushed := Pushed + 1;
        exit(true);
    end;

    /// <summary>
    /// Escapes a text value for embedding into a JSON string payload.
    /// </summary>
    local procedure EscapeJson(Value: Text): Text
    begin
        exit(Value.Replace('\', '\\').Replace('"', '\"'));
    end;

    /// <summary>
    /// Creates the customer logins of a shop in nopCommerce (POST /api/bc/customers/register).
    /// One call per row with status Draft: the account is created with the row e-mail, the
    /// initial password and the row name. Successful rows become Active and store the
    /// nopCommerce customer id; failed rows keep their status and get a sync error.
    /// Several logins per customer (Debitor) are possible - every order of any of these
    /// logins is later assigned to the same Business Central Bill-to customer (row "Customer No.").
    /// </summary>
    internal procedure PushCustomers(Shop: Record "Nop Commerce Shop")
    var
        NopCustomerLogin: Record "Nop Customer Login";
        Pushed: Integer;
        Failed: Integer;
        Total: Integer;
        PushMsg: Label 'Customer logins of the shop "%1" pushed: %2 successful, %3 failed.';
        NoRowsMsg: Label 'No customer logins exist for the shop "%1" yet. Create the logins via Customers and push again.';
        AllActiveMsg: Label 'All %1 customer logins of the shop "%2" are already active in the store - nothing new to push.';
    begin
        Shop.ValidateSetup();
        Pushed := 0;
        Failed := 0;

        NopCustomerLogin.SetRange("Shop Code", Shop.Code);
        NopCustomerLogin.SetRange(Status, "Nop Customer Status"::Draft);
        if NopCustomerLogin.FindSet() then
            repeat
                if not PushCustomerLogin(NopCustomerLogin, Shop) then
                    Failed := Failed + 1
                else
                    Pushed := Pushed + 1;
            until NopCustomerLogin.Next() = 0;

        if Pushed + Failed = 0 then begin
            NopCustomerLogin.SetRange("Shop Code", Shop.Code);
            NopCustomerLogin.SetRange(Status);
            Total := NopCustomerLogin.Count();
            if Total = 0 then
                Message(NoRowsMsg, Shop.Code)
            else
                Message(AllActiveMsg, Total, Shop.Code);
        end else
            Message(PushMsg, Shop.Code, Pushed, Failed);
    end;

    /// <summary>
    /// Transfers one single customer login row to nopCommerce (per-row action "Push Login"
    /// of the Customers page). The account is registered if the e-mail does not exist in the
    /// shop yet; if the account already exists (e.g. registered via the storefront earlier),
    /// the existing nopCommerce customer id is synchronized back into Business Central - no
    /// second account is created and the existing account is not changed.
    /// </summary>
    internal procedure PushCustomerLoginRow(NopCustomerLogin: Record "Nop Customer Login")
    var
        Shop: Record "Nop Commerce Shop";
        PushedOkMsg: Label 'Customer login "%1" transferred (nopCommerce customer id %2).';
        PushedNoIdMsg: Label 'Customer login "%1" transferred to the shop.';
        PushedFailMsg: Label 'Customer login "%1" could not be transferred: %2';
    begin
        if NopCustomerLogin."E-mail" = '' then
            Error('The customer login has no e-mail address.');
        if not Shop.Get(NopCustomerLogin."Shop Code") then
            Error('The shop "%1" does not exist.', NopCustomerLogin."Shop Code");
        Shop.ValidateSetup();
        if PushCustomerLogin(NopCustomerLogin, Shop) then begin
            if NopCustomerLogin."Nop Customer Id" <> 0 then
                Message(PushedOkMsg, NopCustomerLogin."E-mail", NopCustomerLogin."Nop Customer Id")
            else
                Message(PushedNoIdMsg, NopCustomerLogin."E-mail");
        end else
            Message(PushedFailMsg, NopCustomerLogin."E-mail", NopCustomerLogin."Last Sync Error");
    end;

    /// <summary>
    /// Registers one customer login (row) in nopCommerce and updates the row.
    /// </summary>
    /// <returns>True if the row was processed successfully.</returns>
    local procedure PushCustomerLogin(NopCustomerLogin: Record "Nop Customer Login"; Shop: Record "Nop Commerce Shop"): Boolean
    var
        NopHttp: Codeunit "Nop Commerce Http";
        ResponseText: Text;
        JResponse: JsonToken;
        JToken: JsonToken;
        Payload: Text;
        LoginName: Text;
        CustomerId: Integer;
        Created: Boolean;
    begin
        if NopCustomerLogin.Name <> '' then
            LoginName := NopCustomerLogin.Name
        else
            LoginName := NopCustomerLogin."Customer No.";
        Payload := '{"email":"' + EscapeJson(NopCustomerLogin."E-mail") + '","password":"' + EscapeJson(NopCustomerLogin."Initial Password") + '","name":"' + EscapeJson(LoginName) + '","customerNo":"' + EscapeJson(NopCustomerLogin."Customer No.") + '"}';

        if not NopHttp.Post(Shop, 'api/bc/customers/register', Payload, ResponseText) then begin
            NopCustomerLogin."Last Sync Error" := CopyStr(ResponseText, 1, 250);
            NopCustomerLogin.Modify();
            exit(false);
        end;

        CustomerId := 0;
        Created := false;
        if JResponse.ReadFrom(ResponseText) then begin
            if JResponse.SelectToken('$.customerId', JToken) and JToken.IsValue and not JToken.AsValue().IsNull then
                CustomerId := JToken.AsValue().AsInteger();
            if JResponse.SelectToken('$.created', JToken) and JToken.IsValue and not JToken.AsValue().IsNull then
                Created := JToken.AsValue().AsBoolean();
        end;

        NopCustomerLogin."Last Sync Error" := '';
        if CustomerId <> 0 then
            NopCustomerLogin."Nop Customer Id" := CustomerId;
        NopCustomerLogin."Synchronized Date" := CurrentDateTime();
        NopCustomerLogin.Status := "Nop Customer Status"::Active;
        NopCustomerLogin.Modify();
        exit(true);
    end;

    /// <summary>
    /// Imports the orders of a shop from nopCommerce (GET /api/bc/orders) into the
    /// staging tables "Nop Order"/"Nop Order Line" (upsert by nopCommerce order id).
    /// The Bill-to customer is mapped via the customer login rows ("Nop Customer Login",
    /// e-mail of the ordering login); several logins of one customer therefore always
    /// land on the same Bill-to customer.
    /// </summary>
    internal procedure ImportOrders(Shop: Record "Nop Commerce Shop")
    var
        NopHttp: Codeunit "Nop Commerce Http";
        NopCustomerLogin: Record "Nop Customer Login";
        NopOrder: Record "Nop Order";
        ResponseText: Text;
        JResponse: JsonToken;
        JOrders: JsonToken;
        JArray: JsonArray;
        JOrder: JsonToken;
        OrderId: Integer;
        Imported: Integer;
        Unmapped: Integer;
        ImportMsg: Label 'Orders of the shop "%1" imported: %2. %3 order(s) without a mapped customer (no matching login).';
    begin
        Shop.ValidateSetup();
        Imported := 0;
        Unmapped := 0;

        if not NopHttp.Get(Shop, 'api/bc/orders?max=500', ResponseText) then
            Error('The orders of the shop "%1" could not be imported. %2', Shop.Code, CopyStr(ResponseText, 1, 200));
        if not JResponse.ReadFrom(ResponseText) then
            Error('The orders of the shop "%1" could not be parsed.', Shop.Code);
        if not JResponse.SelectToken('$.orders', JOrders) or not TryGetArray(JOrders, JArray) then
            Error('The order export of the shop "%1" does not contain the expected "orders" array.', Shop.Code);

        foreach JOrder in JArray do begin
            if not TryGetInt(JOrder, '$.id', OrderId) then
                Error('An order of the shop "%1" is missing the "id".', Shop.Code);
            if OrderId = 0 then
                Error('An order of the shop "%1" has an invalid "id".', Shop.Code);

            //remove previous snapshot (upsert by nopCommerce order id)
            DeleteOrderSnapshot(Shop.Code, OrderId);

            if InsertOrder(JOrder, Shop.Code, OrderId, NopCustomerLogin) then
                Imported := Imported + 1
            else
                Unmapped := Unmapped + 1;
        end;

        Shop."Last Order Import" := CurrentDateTime();
        Shop.Modify();

        Message(ImportMsg, Shop.Code, Imported, Unmapped);
    end;

    local procedure DeleteOrderSnapshot(ShopCode: Code[10]; OrderId: Integer)
    var
        NopOrder: Record "Nop Order";
        NopOrderLine: Record "Nop Order Line";
    begin
        NopOrderLine.SetRange("Shop Code", ShopCode);
        NopOrderLine.SetRange("Nop Order Id", OrderId);
        NopOrderLine.DeleteAll();

        NopOrder.SetRange("Shop Code", ShopCode);
        NopOrder.SetRange("Nop Order Id", OrderId);
        NopOrder.DeleteAll();
    end;

    /// <summary>
    /// Inserts one order snapshot (header + lines) for the shop.
    /// </summary>
    /// <returns>False if the order could not be mapped to a customer login.</returns>
    local procedure InsertOrder(JOrder: JsonToken; ShopCode: Code[10]; OrderId: Integer; NopCustomerLogin: Record "Nop Customer Login"): Boolean
    var
        NopOrder: Record "Nop Order";
        NopOrderLine: Record "Nop Order Line";
        JItems: JsonToken;
        JArray: JsonArray;
        JItem: JsonToken;
        JVal: JsonToken;
        OrderNo: Code[30];
        Email: Text;
        CustomerNo: Code[20];
        BillToName: Text;
        BillToLine: Text;
        ShipToName: Text;
        ShipToLine: Text;
        CurrencyCode: Code[10];
        OrderTotal: Decimal;
        OrderDate: DateTime;
        StatusCode: Code[20];
        PaymentCode: Code[20];
        ShippingCode: Code[20];
        StatusId: Integer;
        PaymentId: Integer;
        ShippingId: Integer;
        Sku: Code[20];
        Description: Text;
        Quantity: Decimal;
        UnitPrice: Decimal;
        LineTotal: Decimal;
        LineNo: Integer;
    begin
        TryGetCode(JOrder, '$.orderNumber', OrderNo);
        TryGetText(JOrder, '$.customerEmail', Email);
        TryGetCode(JOrder, '$.currencyCode', CurrencyCode);
        TryGetDec(JOrder, '$.orderTotal', OrderTotal);
        TryGetDate(JOrder, '$.createdOnUtc', OrderDate);
        TryGetInt(JOrder, '$.orderStatusId', StatusId);
        TryGetInt(JOrder, '$.paymentStatusId', PaymentId);
        TryGetInt(JOrder, '$.shippingStatusId', ShippingId);
        StatusCode := MapOrderStatus(StatusId);
        PaymentCode := MapPaymentStatus(PaymentId);
        ShippingCode := MapShippingStatus(ShippingId);

        //bill-to customer: mapped via the login of the ordering customer
        NopCustomerLogin.SetRange("Shop Code", ShopCode);
        NopCustomerLogin.SetRange("E-mail", Email);
        if NopCustomerLogin.FindFirst() then
            CustomerNo := NopCustomerLogin."Customer No.";

        //address snapshots for the overview
        if JOrder.SelectToken('$.billingAddress', JVal) and JVal.IsObject then
            GetAddressTexts(JOrder, '$.billingAddress', BillToName, BillToLine);
        if JOrder.SelectToken('$.shippingAddress', JVal) and JVal.IsObject then
            GetAddressTexts(JOrder, '$.shippingAddress', ShipToName, ShipToLine);

        if CustomerNo = '' then
            exit(false);

        NopOrder.Init();
        NopOrder."Shop Code" := ShopCode;
        NopOrder."Nop Order Id" := OrderId;
        NopOrder."Order No." := OrderNo;
        NopOrder."Order Date" := OrderDate;
        NopOrder."Order Status" := StatusCode;
        NopOrder."Payment Status" := PaymentCode;
        NopOrder."Shipping Status" := ShippingCode;
        NopOrder."Currency Code" := CurrencyCode;
        NopOrder."Order Total" := OrderTotal;
        NopOrder."Customer E-mail" := Email;
        NopOrder."Bill-to Customer No." := CustomerNo;
        NopOrder."Bill-to Name" := BillToName;
        NopOrder."Ship-to Name" := ShipToName;
        NopOrder."Ship-to Address" := ShipToLine;
        NopOrder."Imported Date" := CurrentDateTime();
        NopOrder.Insert();

        if JOrder.SelectToken('$.items', JItems) and TryGetArray(JItems, JArray) then begin
            LineNo := 0;
            foreach JItem in JArray do begin
                LineNo := LineNo + 10000;
                TryGetCode(JItem, '$.sku', Sku);
                TryGetText(JItem, '$.productName', Description);
                TryGetDec(JItem, '$.quantity', Quantity);
                TryGetDec(JItem, '$.unitPriceExclTax', UnitPrice);
                TryGetDec(JItem, '$.lineTotalInclTax', LineTotal);

                NopOrderLine.Init();
                NopOrderLine."Shop Code" := ShopCode;
                NopOrderLine."Nop Order Id" := OrderId;
                NopOrderLine."Line No." := LineNo;
                NopOrderLine.SKU := Sku;
                NopOrderLine."Item Description" := Description;
                NopOrderLine.Quantity := Quantity;
                NopOrderLine."Unit Price" := UnitPrice;
                NopOrderLine."Line Amount" := LineTotal;
                NopOrderLine.Insert();
            end;
        end;
        exit(true);
    end;

    local procedure GetAddressTexts(JRoot: JsonToken; JsonPath: Text; var FullName: Text; var AddressLine: Text)
    var
        First: Text;
        Last: Text;
        Company: Text;
        Street: Text;
        City: Text;
        Zip: Text;
    begin
        TryGetText(JRoot, JsonPath + '.firstName', First);
        TryGetText(JRoot, JsonPath + '.lastName', Last);
        TryGetText(JRoot, JsonPath + '.company', Company);
        TryGetText(JRoot, JsonPath + '.address1', Street);
        TryGetText(JRoot, JsonPath + '.city', City);
        TryGetText(JRoot, JsonPath + '.zipPostalCode', Zip);

        FullName := CopyStr(First + ' ' + Last, 1, 100);
        if Company <> '' then
            FullName := CopyStr(Company, 1, 100);
        AddressLine := CopyStr(Street + ', ' + Zip + ' ' + City, 1, 250);
    end;

    local procedure MapOrderStatus(StatusId: Integer): Code[20]
    begin
        case StatusId of
            10: exit('Pending');
            20: exit('Processing');
            30: exit('Complete');
            40: exit('Cancelled');
        end;
        exit('');
    end;

    local procedure MapPaymentStatus(StatusId: Integer): Code[20]
    begin
        case StatusId of
            10: exit('Pending');
            20: exit('Authorized');
            30: exit('Paid');
            40: exit('Refunded');
            50: exit('Voided');
        end;
        exit('');
    end;

    local procedure MapShippingStatus(StatusId: Integer): Code[20]
    begin
        case StatusId of
            10: exit('NotYetShipped');
            20: exit('Shipped');
            25: exit('PartiallyShipped');
            30: exit('Delivered');
        end;
        exit('');
    end;

    [TryFunction]
    local procedure TryGetDec(JToken: JsonToken; JsonPath: Text; var Value: Decimal)
    var
        JValue: JsonToken;
    begin
        if JToken.SelectToken(JsonPath, JValue) and JValue.IsValue and not JValue.AsValue().IsNull then
            Evaluate(Value, JValue.AsValue().AsText());
    end;

    [TryFunction]
    local procedure TryGetDate(JToken: JsonToken; JsonPath: Text; var Value: DateTime)
    var
        JValue: JsonToken;
    begin
        if JToken.SelectToken(JsonPath, JValue) and JValue.IsValue and not JValue.AsValue().IsNull then
            Value := JValue.AsValue().AsDateTime();
    end;

    [TryFunction]
    local procedure TryGetArray(JToken: JsonToken; var JArray: JsonArray)
    begin
        if JToken.IsArray then
            JArray := JToken.AsArray();
    end;

    [TryFunction]
    local procedure TryGetInt(JToken: JsonToken; JsonPath: Text; var Value: Integer)
    var
        JValue: JsonToken;
    begin
        if JToken.SelectToken(JsonPath, JValue) and JValue.IsValue and not JValue.AsValue().IsNull then
            Value := JValue.AsValue().AsInteger();
    end;

    [TryFunction]
    local procedure TryGetText(JToken: JsonToken; JsonPath: Text; var Value: Text)
    var
        JValue: JsonToken;
    begin
        if JToken.SelectToken(JsonPath, JValue) and JValue.IsValue and not JValue.AsValue().IsNull then
            Value := JValue.AsValue().AsText();
    end;

    [TryFunction]
    local procedure TryGetCode(JToken: JsonToken; JsonPath: Text; var Value: Code[20])
    var
        JValue: JsonToken;
    begin
        if JToken.SelectToken(JsonPath, JValue) and JValue.IsValue and not JValue.AsValue().IsNull then
            Value := JValue.AsValue().AsCode();
    end;

    [TryFunction]
    local procedure TryGetBool(JToken: JsonToken; JsonPath: Text; var Value: Boolean)
    var
        JValue: JsonToken;
    begin
        if JToken.SelectToken(JsonPath, JValue) and JValue.IsValue and not JValue.AsValue().IsNull then
            Value := JValue.AsValue().AsBoolean();
    end;
}
