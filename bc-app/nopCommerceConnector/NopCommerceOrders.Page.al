namespace NopCommerceConnector;

/// <summary>
/// List of the imported nopCommerce orders per shop ("Nop Order", staging snapshot).
/// Opened via the "Orders" action of the shop (Setup/card and Shops list); the page is
/// filtered to the shop. Every order of any login of a customer is listed with the same
/// "Bill-to Customer No." (mapped via the customer login rows).
/// </summary>
page 62126 "Nop Commerce Orders"
{
    ApplicationArea = All;
    Caption = 'nopCommerce Orders';
    PageType = List;
    SourceTable = "Nop Order";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Orders)
            {
                field("Shop Code"; Rec."Shop Code")
                {
                    Caption = 'Shop Code';
                }
                field("Order No."; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    Caption = 'Order Date';
                }
                field("Order Status"; Rec."Order Status")
                {
                    Caption = 'Order Status';
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer No.';
                }
                field("Customer E-mail"; Rec."Customer E-mail")
                {
                    Caption = 'Customer E-mail';
                }
                field("Order Total"; Rec."Order Total")
                {
                    Caption = 'Order Total';
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

    procedure SetShopCode(ShopCode: Code[10])
    begin
        NopShopCode := ShopCode;
    end;
}
