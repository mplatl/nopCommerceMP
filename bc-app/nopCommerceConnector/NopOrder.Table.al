namespace NopCommerceConnector;

/// <summary>
/// Imported nopCommerce order (staging/snapshot per shop, source of truth is the
/// nopCommerce store). Orders are pulled per shop ("Get Orders") and kept by the
/// nopCommerce order id (upsert). The Bill-to customer is mapped from the matching
/// "Nop Customer Login" (e-mail) of the shop - several logins of a customer therefore
/// always land on the same Bill-to customer.
/// </summary>
table 62117 "Nop Order"
{
    Caption = 'nopCommerce Order';
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
        field(2; "Nop Order Id"; Integer)
        {
            Caption = 'nopCommerce Order Id';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Identifier of the order in the nopCommerce store.';
        }
        field(3; "Order No."; Code[30])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
        }
        field(4; "Order Date"; DateTime)
        {
            Caption = 'Order Date';
            DataClassification = CustomerContent;
        }
        field(5; "Order Status"; Code[20])
        {
            Caption = 'Order Status';
            DataClassification = CustomerContent;
            ToolTip = 'Status of the order in the nopCommerce store (Pending/Processing/Complete/Cancelled).';
        }
        field(6; "Payment Status"; Code[20])
        {
            Caption = 'Payment Status';
            DataClassification = CustomerContent;
        }
        field(7; "Shipping Status"; Code[20])
        {
            Caption = 'Shipping Status';
            DataClassification = CustomerContent;
        }
        field(8; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }
        field(9; "Order Total"; Decimal)
        {
            Caption = 'Order Total';
            DataClassification = CustomerContent;
        }
        field(10; "Customer E-mail"; Text[250])
        {
            Caption = 'Customer E-mail';
            DataClassification = CustomerContent;
        }
        field(11; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            DataClassification = CustomerContent;
            ToolTip = 'Business Central customer (Debitor) that is billed - mapped from the login of the ordering customer.';
        }
        field(12; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            DataClassification = CustomerContent;
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            DataClassification = CustomerContent;
        }
        field(14; "Ship-to Address"; Text[250])
        {
            Caption = 'Ship-to Address';
            DataClassification = CustomerContent;
        }
        field(15; "Imported Date"; DateTime)
        {
            Caption = 'Imported Date';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Date and time when the order was last imported from the nopCommerce store.';
        }
    }

    keys
    {
        key(PK; "Shop Code", "Nop Order Id")
        {
            Clustered = true;
        }
    }
}
