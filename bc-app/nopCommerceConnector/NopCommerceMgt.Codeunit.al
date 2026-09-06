namespace NopCommerceConnector;

/// <summary>
/// Central management codeunit for the nopCommerce integration (mirrors the Microsoft Shopify "Mgt." codeunits).
/// Business Central is the orchestrator/master: it calls the plugin API of the shops (pull and push);
/// nopCommerce only answers REST calls (X-Api-Key) and never initiates requests.
/// Implemented: connection test (health) and the language pull per shop ("Nop Language").
/// Open: product push (POST /api/bc/products) and order/customer import (GET /api/bc/orders|customers).
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
