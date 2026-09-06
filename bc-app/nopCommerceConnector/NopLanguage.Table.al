namespace NopCommerceConnector;

/// <summary>
/// Represents a nopCommerce language that is used by a shop (linked to the shop).
/// Mirrors the "Language" records of the connected nopCommerce store per shop and
/// marks the default language of the shop. Basis for the later per-language transfer
/// of localized product texts (nopCommerce stores localized text per language).
/// Like "Nop Product": only languages with a record here are used for the shop
/// (whitelist) — later the language data can be pulled from nopCommerce
/// (GET /api/bc/languages) via the connection of the shop.
/// </summary>
table 62111 "Nop Language"
{
    Caption = 'nopCommerce Language';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shop Code"; Code[10])
        {
            Caption = 'Shop Code';
            DataClassification = CustomerContent;
            TableRelation = "Nop Commerce Shop".Code;
            NotBlank = true;
        }
        field(2; "Language ID"; Integer)
        {
            Caption = 'Language ID';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'ID of the language in the nopCommerce store (e.g. from the language edit URL /Admin/Language/Edit/{id}).';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Name of the language as shown in the nopCommerce store, e.g. "Deutsch (Österreich)".';
        }
        field(4; "Language Culture"; Code[20])
        {
            Caption = 'Language Culture';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Culture code of the language, e.g. de-AT or en-US.';
        }
        field(5; "Unique SEO Code"; Code[20])
        {
            Caption = 'Unique SEO Code';
            DataClassification = CustomerContent;
            ToolTip = 'Unique SEO code of the language in the nopCommerce store (e.g. en).';
        }
        field(6; RTL; Boolean)
        {
            Caption = 'RTL';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the language is a right-to-left language.';
        }
        field(7; Published; Boolean)
        {
            Caption = 'Published';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the language is published (enabled) in the nopCommerce store.';
        }
        field(8; "Display Order"; Integer)
        {
            Caption = 'Display Order';
            DataClassification = CustomerContent;
            ToolTip = 'Display order of the language in the nopCommerce store.';
        }
        field(9; "Is Default"; Boolean)
        {
            Caption = 'Is Default';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the default language of this shop (used for shop communication and as fallback language). Only one language per shop should be flagged as default.';
        }
        field(10; "Synchronized Date"; DateTime)
        {
            Caption = 'Synchronized Date';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Date and time of the last successful synchronization of the language data from the nopCommerce store.';
        }
        field(11; "Last Sync Error"; Text[250])
        {
            Caption = 'Last Sync Error';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Error message of the last failed synchronization of the language data, if any.';
        }
    }

    keys
    {
        key(PK; "Shop Code", "Language ID")
        {
            Clustered = true;
        }
    }
}
