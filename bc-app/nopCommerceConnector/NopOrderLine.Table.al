namespace NopCommerceConnector;

/// <summary>
/// Line items of an imported nopCommerce order (staging snapshot per shop).
/// </summary>
table 62118 "Nop Order Line"
{
    Caption = 'nopCommerce Order Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shop Code"; Code[10])
        {
            Caption = 'Shop Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; "Nop Order Id"; Integer)
        {
            Caption = 'nopCommerce Order Id';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(4; SKU; Code[20])
        {
            Caption = 'SKU';
            DataClassification = CustomerContent;
        }
        field(5; "Item Description"; Text[250])
        {
            Caption = 'Item Description';
            DataClassification = CustomerContent;
        }
        field(6; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }
        field(7; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = CustomerContent;
        }
        field(8; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Shop Code", "Nop Order Id", "Line No.")
        {
            Clustered = true;
        }
    }
}
