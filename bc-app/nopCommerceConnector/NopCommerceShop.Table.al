namespace NopCommerceConnector;

/// <summary>
/// Represents a nopCommerce shop (sales channel) connected to Business Central.
/// Mirrors the "Shopify Shop" concept of the Microsoft Shopify Connector.
/// </summary>
table 62100 "Nop Commerce Shop"
{
    Caption = 'NopCommerce Shop';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
        }
        field(4; "Nop Commerce URL"; Text[250])
        {
            Caption = 'NopCommerce URL';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(5; "API Key"; Text[250])
        {
            Caption = 'API Key';
            DataClassification = EndUserIdentifiableInformation;
            //the key authorizes requests from Business Central to the nopCommerce plugin endpoints
        }
        field(6; "API Key Set"; Boolean)
        {
            Caption = 'API Key Set';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Sync Products"; Boolean)
        {
            Caption = 'Sync Products';
            DataClassification = CustomerContent;
            //when enabled, selected items are exported to nopCommerce
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Validates that the shop has all required connection data
    /// </summary>
    internal procedure ValidateSetup()
    var
        NopShopSetupValidationErr: Label 'The shop "%1" is missing connection data. Enter the nopCommerce URL and the API key.';
    begin
        if "Nop Commerce URL" = '' then
            Error(NopShopSetupValidationErr, Code);
        if "API Key" = '' then
            Error(NopShopSetupValidationErr, Code);
    end;

    trigger OnInsert()
    begin
        "API Key Set" := "API Key" <> '';
    end;

    trigger OnModify()
    begin
        "API Key Set" := "API Key" <> '';
    end;
}
