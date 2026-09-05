namespace NopCommerceConnector;

using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Card to create and edit a saved item search filter (with code).
/// The filter combines item filters (No., description, item category) with an optional
/// attribute filter (set via the standard item attribute search) and targets one shop
/// with a default status.
/// </summary>
page 62106 "Nop Product Filter"
{
    ApplicationArea = All;
    Caption = 'nopCommerce Product Filter';
    PageType = Card;
    SourceTable = "Nop Product Filter";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
            }
            group(Target)
            {
                Caption = 'Target';

                field("Shop Code"; Rec."Shop Code")
                {
                    Caption = 'Shop Code';
                }
                field("Default Status"; Rec."Default Status")
                {
                    Caption = 'Default Status';
                }
            }
            group(ItemFilter)
            {
                Caption = 'Item Filter';

                field("Item No. Filter"; Rec."Item No. Filter")
                {
                    Caption = 'Item No. Filter';
                }
                field("Description Filter"; Rec."Description Filter")
                {
                    Caption = 'Description Filter';
                }
                field("Item Category Filter"; Rec."Item Category Filter")
                {
                    Caption = 'Item Category Filter';
                }
            }
            group(AttributeFilter)
            {
                Caption = 'Attribute Filter';

                field("Attribute Filter"; Rec."Attribute Filter")
                {
                    Caption = 'Attribute Filter';
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AttributeSearch)
            {
                ApplicationArea = All;
                Caption = 'Attribute Search';
                ToolTip = 'Search the items by attributes with the standard attribute search. The criteria are stored in this filter.';
                trigger OnAction()
                begin
                    SetAttributeFilterFromStandardSearch();
                end;
            }
            action(SearchItems)
            {
                ApplicationArea = All;
                Caption = 'Search Items';
                ToolTip = 'Search the items matching this filter and add them to the store products.';
                trigger OnAction()
                var
                    NopItemSearch: Page "Nop Item Search";
                begin
                    NopItemSearch.SetFilterCode(Rec.Code);
                    NopItemSearch.Run();
                end;
            }
            action(StoreProducts)
            {
                ApplicationArea = All;
                Caption = 'Store Products';
                ToolTip = 'Open the store products of the target shop.';
                trigger OnAction()
                var
                    NopCommerceProducts: Page "Nop Commerce Products";
                begin
                    NopCommerceProducts.SetShopCode(Rec."Shop Code");
                    NopCommerceProducts.Run();
                end;
            }
        }
    }

    local procedure SetAttributeFilterFromStandardSearch()
    var
        NopStoreProducts: Codeunit "Nop Store Products";
        TempFilter: Record "Filter Item Attributes Buffer" temporary;
    begin
        //run the standard attribute search dialog; the buffer then contains the chosen criteria
        if not NopStoreProducts.RunAttributeSearchDialog(TempFilter) then
            exit;

        Rec."Attribute Filter" := NopStoreProducts.GetCriteriaText(TempFilter);
    end;
}
