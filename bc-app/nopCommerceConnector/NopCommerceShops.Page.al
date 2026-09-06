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
    CardPageId = "Nop Commerce Setup";

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
            action(ProductFilters)
            {
                ApplicationArea = All;
                Caption = 'Saved Filters';
                ToolTip = 'Manage the saved search filters that add items to store products.';
                RunObject = Page "Nop Product Filters";
            }
            action(Languages)
            {
                ApplicationArea = All;
                Caption = 'Languages';
                ToolTip = 'Manage the nopCommerce languages of the selected shop (per shop). The default language of the shop is used for shop communication and as fallback for product texts.';
                trigger OnAction()
                var
                    NopCommerceLanguages: Page "Nop Commerce Languages";
                begin
                    NopCommerceLanguages.SetShopCode(Rec.Code);
                    NopCommerceLanguages.Run();
                end;
            }
            action(GetLanguages)
            {
                ApplicationArea = All;
                Caption = 'Get Languages';
                ToolTip = 'Pulls the nopCommerce languages of the selected shop from the plugin API (per-shop whitelist update) and opens the language list.';
                trigger OnAction()
                var
                    NopLanguageSync: Codeunit "Nop Commerce Mgt.";
                    NopCommerceLanguages: Page "Nop Commerce Languages";
                begin
                    NopLanguageSync.SyncLanguages(Rec);
                    NopCommerceLanguages.SetShopCode(Rec.Code);
                    NopCommerceLanguages.Run();
                end;
            }
            action(PushProducts)
            {
                Caption = 'Push Products';
                ToolTip = 'Exports the selected store products of this shop to nopCommerce (creates/updates them or removes archived ones).';
                ApplicationArea = All;
                trigger OnAction()
                var
                    NopProductSync: Codeunit "Nop Commerce Mgt.";
                begin
                    NopProductSync.PushProducts(Rec);
                end;
            }
        }
    }
}
