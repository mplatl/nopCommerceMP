namespace NopCommerceConnector;

/// <summary>
/// Setup card for the nopCommerce connection (mirrors the Shopify shop card).
/// </summary>
page 62100 "Nop Commerce Setup"
{
    ApplicationArea = All;
    PageType = Card;
    SourceTable = "Nop Commerce Shop";
    Caption = 'nopCommerce Connection';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec.Code)
                {
                    Caption = 'Code';
                }
                field("Description"; Rec.Description)
                {
                    Caption = 'Description';
                }
                field("Nop Store Name"; Rec."Nop Store Name")
                {
                    Caption = 'nopCommerce Store Name';
                    ToolTip = 'The name of the matching store inside nopCommerce (multistore). Leave empty to fall back to the shop description.';
                }
                field("Enabled"; Rec.Enabled)
                {
                    Caption = 'Enabled';
                }
            }
            group(Connection)
            {
                Caption = 'Connection';

                field("Nop Commerce URL"; Rec."Nop Commerce URL")
                {
                    Caption = 'nopCommerce URL';
                    ToolTip = 'The public URL of the nopCommerce store (used by the Business Central service to call the plugin API endpoints).';
                }
                field("API Key"; Rec."API Key")
                {
                    Caption = 'API Key';
                    ShowCaption = false;
                    ToolTip = 'The API key issued by the nopCommerce plugin. Requests from Business Central are authenticated with this key.';
                }
            }
            group("Sync Options")
            {
                Caption = 'Sync Options';

                field("Sync Products"; Rec."Sync Products")
                {
                    Caption = 'Sync Products';
                    ToolTip = 'Enable to export the selected products of this shop to nopCommerce.';
                }
                field("Sync Prices"; Rec."Sync Prices")
                {
                    Caption = 'Sync Prices';
                    ToolTip = 'Enable to transfer the unit price of the selected products to nopCommerce.';
                }
                field("Sync Inventory"; Rec."Sync Inventory")
                {
                    Caption = 'Sync Inventory';
                    ToolTip = 'Enable to transfer the available stock of the selected products to nopCommerce.';
                }
                field("Sync Images"; Rec."Sync Images")
                {
                    Caption = 'Sync Images';
                    ToolTip = 'Enable to transfer the item picture of the selected products to nopCommerce.';
                }
            }
            group("Import Options")
            {
                Caption = 'Import Options';

                field("Import Customers"; Rec."Import Customers")
                {
                    Caption = 'Import Customers';
                    ToolTip = 'Enable to import the customers of this nopCommerce store into Business Central.';
                }
                field("Import Orders"; Rec."Import Orders")
                {
                    Caption = 'Import Orders';
                    ToolTip = 'Enable to import the orders of this nopCommerce store into Business Central.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Products)
            {
                Caption = 'Products';
                ToolTip = 'Manage the products of this shop that are exported to nopCommerce. Only products listed here are synchronized.';
                ApplicationArea = All;
                trigger OnAction()
                var
                    NopCommerceProducts: Page "Nop Commerce Products";
                begin
                    NopCommerceProducts.SetShopCode(Rec.Code);
                    NopCommerceProducts.Run();
                end;
            }
            action(AddItems)
            {
                Caption = 'Search & Add Items';
                ToolTip = 'Search items (also by saved filters) and add them to the store products of this shop.';
                ApplicationArea = All;
                trigger OnAction()
                var
                    NopItemSearch: Page "Nop Item Search";
                begin
                    NopItemSearch.SetShopCode(Rec.Code);
                    NopItemSearch.Run();
                end;
            }
            action(ProductFilters)
            {
                Caption = 'Saved Filters';
                ToolTip = 'Manage the saved search filters (item + attribute filters) that add items to store products.';
                ApplicationArea = All;
                RunObject = Page "Nop Product Filters";
            }
            action(Languages)
            {
                Caption = 'Languages';
                ToolTip = 'Manage the nopCommerce languages that are used by this shop (per shop). The default language of the shop is used for shop communication and as fallback for product texts.';
                ApplicationArea = All;
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
                Caption = 'Get Languages';
                ToolTip = 'Pulls the nopCommerce languages of this shop from the plugin API (per-shop whitelist update) and opens the language list.';
                ApplicationArea = All;
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
            action(TestConnection)
            {
                Caption = 'Test Connection';
                ToolTip = 'Verifies that Business Central can reach the nopCommerce plugin API of this shop.';
                ApplicationArea = All;
                Visible = Rec.Enabled;
                trigger OnAction()
                var
                    NopConnectorMgt: Codeunit "Nop Commerce Mgt.";
                begin
                    NopConnectorMgt.TestConnection(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec."API Key Set" := Rec."API Key" <> '';
    end;
}
