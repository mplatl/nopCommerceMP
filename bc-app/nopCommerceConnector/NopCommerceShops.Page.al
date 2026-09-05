namespace NopCommerceConnector;

/// <summary>
/// List of the nopCommerce shops (sales channels) connected to Business Central.
/// Each shop maps to one store inside nopCommerce (multistore) via its store name.
/// </summary>
page 62102 "Nop Commerce Shops"
{
    ApplicationArea = All;
    PageType = List;
    SourceTable = "Nop Commerce Shop";
    Caption = 'nopCommerce Shops';
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Shops)
            {
                field(Code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field("Nop Store Name"; Rec."Nop Store Name")
                {
                    Caption = 'nopCommerce Store Name';
                }
                field(Enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
                }
                field("Sync Products"; Rec."Sync Products")
                {
                    Caption = 'Sync Products';
                }
                field("Import Orders"; Rec."Import Orders")
                {
                    Caption = 'Import Orders';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(StoreProducts)
            {
                ApplicationArea = All;
                Caption = 'Store Products';
                ToolTip = 'Open the products of the selected shop (filtered by shop).';
                Visible = Rec.Code <> '';
                trigger OnAction()
                var
                    NopCommerceProducts: Page "Nop Commerce Products";
                begin
                    NopCommerceProducts.SetShopCode(Rec.Code);
                    NopCommerceProducts.Run();
                end;
            }
            action(AddStoreProducts)
            {
                ApplicationArea = All;
                Caption = 'Add Store Products';
                ToolTip = 'Add items to the selected shop via item and attribute filters.';
                Visible = Rec.Code <> '';
                trigger OnAction()
                var
                    AddStoreProductsReport: Report "Add Store Products";
                begin
                    AddStoreProductsReport.SetShopCode(Rec.Code);
                    AddStoreProductsReport.Run();
                end;
            }
            action(OpenCard)
            {
                ApplicationArea = All;
                Caption = 'Card';
                ToolTip = 'Open the shop card of the selected shop.';
                Visible = Rec.Code <> '';
                RunObject = Page "Nop Commerce Setup";
                RunPageMode = Edit;
            }
        }
    }
}
