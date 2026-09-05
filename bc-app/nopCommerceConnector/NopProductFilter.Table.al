namespace NopCommerceConnector;

using Microsoft.Inventory.Item;

/// <summary>
/// Represents a saved search filter (with code) that is used to find items and add them
/// as store products of a shop. The filter can combine plain item filters (No., description,
/// item category) with an optional item attribute (and value) filter.
/// </summary>
table 62104 "Nop Product Filter"
{
    Caption = 'nopCommerce Product Filter';
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
        field(3; "Shop Code"; Code[10])
        {
            Caption = 'Shop Code';
            DataClassification = CustomerContent;
            TableRelation = "Nop Commerce Shop".Code;
            NotBlank = true;
        }
        field(4; "Default Status"; enum "Nop Product Status")
        {
            Caption = 'Default Status';
            DataClassification = CustomerContent;
            //the status that is set when the found items are added to the store products
        }
        field(5; "Attribute Filter"; Text[250])
        {
            Caption = 'Attribute Filter';
            DataClassification = CustomerContent;
            ToolTip = 'Item attribute search criteria in the format Attribute=Value, entries separated by "|". Set by the standard attribute search.';
        }
        field(7; "Item No. Filter"; Text[250])
        {
            Caption = 'Item No. Filter';
            DataClassification = CustomerContent;
            ToolTip = 'Optional item number filter, e.g. "1896*" or "1896-S|1900-S".';
        }
        field(8; "Description Filter"; Text[250])
        {
            Caption = 'Description Filter';
            DataClassification = CustomerContent;
            ToolTip = 'Optional description filter, e.g. "*Schreibtisch*".';
        }
        field(9; "Item Category Filter"; Code[20])
        {
            Caption = 'Item Category Filter';
            DataClassification = CustomerContent;
            ToolTip = 'Optional item category filter (exact code).';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
