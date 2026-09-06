namespace NopCommerceConnector;

/// <summary>
/// Represents a nopCommerce shop (sales channel) connected to Business Central.
/// Mirrors the "Shopify Shop" concept of the Microsoft Shopify Connector.
/// </summary>
table 62100 "Nop Commerce Shop"
{
    Caption = 'NopCommerce Shop';
    DataClassification = CustomerContent;
    DrillDownPageId = "Nop Commerce Setup";

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
        field(8; "Sync Prices"; Boolean)
        {
            Caption = 'Sync Prices';
            DataClassification = CustomerContent;
            //when enabled, the unit price of the selected items is transferred to nopCommerce
        }
        field(9; "Sync Inventory"; Boolean)
        {
            Caption = 'Sync Inventory';
            DataClassification = CustomerContent;
            //when enabled, the available stock of the selected items is transferred to nopCommerce
        }
        field(10; "Sync Images"; Boolean)
        {
            Caption = 'Sync Images';
            DataClassification = CustomerContent;
            //when enabled, the item picture is transferred to nopCommerce
        }
        field(11; "Import Customers"; Boolean)
        {
            Caption = 'Import Customers';
            DataClassification = CustomerContent;
            //future: import the customers of this nopCommerce store into Business Central
        }
        field(12; "Import Orders"; Boolean)
        {
            Caption = 'Import Orders';
            DataClassification = CustomerContent;
            //future: import the orders of this nopCommerce store into Business Central
        }
        field(13; "Nop Store Name"; Text[100])
        {
            Caption = 'nopCommerce Store Name';
            DataClassification = CustomerContent;
            ToolTip = 'The name of the matching store inside nopCommerce (multistore). Leave empty to fall back to the shop description.';
        }
        field(14; "Last Order Import"; DateTime)
        {
            Caption = 'Last Order Import';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Date and time of the last order import from the nopCommerce store.';
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
        if "Nop Store Name" = '' then
            "Nop Store Name" := Description;
    end;

    trigger OnModify()
    begin
        "API Key Set" := "API Key" <> '';
    end;
}
