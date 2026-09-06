namespace NopCommerceConnector;

/// <summary>
/// List of the customer logins (Debitoren-Logins) per shop ("Nop Customer").
/// Opened via the "Customers" action of the shop (Setup/card and Shops list) —
/// the page is filtered to the shop and new records get the shop code automatically.
/// Several logins per customer (Debitor) are possible (one row per login/e-mail).
/// </summary>
page 62122 "Nop Commerce Customers"
{
    ApplicationArea = All;
    Caption = 'nopCommerce Customers';
    PageType = List;
    SourceTable = "Nop Customer";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Customers)
            {
                field("Customer No."; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field("E-mail"; Rec."E-mail")
                {
                    Caption = 'E-mail';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field("Nop Customer Id"; Rec."Nop Customer Id")
                {
                    Caption = 'nopCommerce Customer Id';
                }
                field("Synchronized Date"; Rec."Synchronized Date")
                {
                    Caption = 'Synchronized Date';
                    Editable = false;
                }
            }
        }
    }

    var
        NopShopCode: Code[10];

    trigger OnOpenPage()
    begin
        if NopShopCode <> '' then
            Rec.SetRange("Shop Code", NopShopCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Shop Code" := NopShopCode;
        Rec.Status := "Nop Customer Status"::Draft;
    end;

    procedure SetShopCode(ShopCode: Code[10])
    begin
        NopShopCode := ShopCode;
    end;
}
