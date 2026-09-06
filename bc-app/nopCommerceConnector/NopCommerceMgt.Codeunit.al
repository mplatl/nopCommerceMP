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
        PushMsg: Label 'Customer logins of the shop "%1" pushed: %2 successful, %3 failed.';
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

        Message(PushMsg, Shop.Code, Pushed, Failed);
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
        CustomerId: Integer;
        Created: Boolean;
    begin
        Payload := '{"email":"' + EscapeJson(NopCustomerLogin."E-mail") + '","password":"' + EscapeJson(NopCustomerLogin."Initial Password") + '","name":"' + EscapeJson(NopCustomerLogin.Name) + '","customerNo":"' + EscapeJson(NopCustomerLogin."Customer No.") + '"}';

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
