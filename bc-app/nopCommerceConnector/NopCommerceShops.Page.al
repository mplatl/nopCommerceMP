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
            action(GetOrders)
            {
                ApplicationArea = All;
                Caption = 'Get Orders';
                ToolTip = 'Imports the orders of this shop from nopCommerce (staging tables "Nop Order").';
                trigger OnAction()
                var
                    NopOrderSync: Codeunit "Nop Commerce Mgt.";
                begin
                    NopOrderSync.ImportOrders(Rec);
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
            action(PushLogins)
            {
                ApplicationArea = All;
                Caption = 'Push Logins';
                ToolTip = 'Creates the customer logins (Draft) of the selected shop in nopCommerce with their initial password (one account per login/e-mail).';
                trigger OnAction()
                var
                    NopCustomerSync: Codeunit "Nop Commerce Mgt.";
                begin
                    NopCustomerSync.PushCustomers(Rec);
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
            action(PushCategories)
            {
                ApplicationArea = All;
                Caption = 'Push Categories';
                ToolTip = 'Creates the categories (Draft) of the selected shop in nopCommerce - parent categories are always created before their subcategories.';
                trigger OnAction()
                var
                    NopCategorySync: Codeunit "Nop Commerce Mgt.";
                begin
                    NopCategorySync.PushCategories(Rec);
                end;
            }
        }

        area(Navigation)
        {
            action(Orders)
            {
                Caption = 'Orders';
                ToolTip = 'Open the imported nopCommerce orders of this shop (staging overview).';
                trigger OnAction()
                var
                    NopCommerceOrders: Page "Nop Commerce Orders";
                begin
                    NopCommerceOrders.SetShopCode(Rec.Code);
                    NopCommerceOrders.Run();
                end;
            }
            action(Customers)
            {
                Caption = 'Customers';
                ToolTip = 'Manage the customer logins (Debitor) of this shop. Several logins per customer are possible; each row = one login in the nopCommerce store.';
                trigger OnAction()
                var
                    NopCommerceCustomers: Page "Nop Commerce Customers";
                begin
                    NopCommerceCustomers.SetShopCode(Rec.Code);
                    NopCommerceCustomers.Run();
                end;
            }
            action(Categories)
            {
                Caption = 'Categories';
                ToolTip = 'Manage the categories of the selected shop. Categories are defined per shop (not matched 1:1 with Business Central) and can have parent categories like in nopCommerce.';
                ApplicationArea = All;
                trigger OnAction()
                var
                    NopCommerceCategories: Page "Nop Commerce Categories";
                begin
                    NopCommerceCategories.SetShopCode(Rec.Code);
                    NopCommerceCategories.Run();
                end;
            }
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
        }
    
    }
}