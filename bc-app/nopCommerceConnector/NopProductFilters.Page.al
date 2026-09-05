namespace NopCommerceConnector;

/// <summary>
/// List of the saved search filters that add items to the store products of a shop.
/// </summary>
page 62105 "Nop Product Filters"
{
    ApplicationArea = All;
    PageType = List;
    SourceTable = "Nop Product Filter";
    Caption = 'nopCommerce Product Filters';
    CardPageId = "Nop Product Filter";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Filters)
            {
                field(Code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field("Shop Code"; Rec."Shop Code")
                {
                    Caption = 'Shop Code';
                }
                field("Default Status"; Rec."Default Status")
                {
                    Caption = 'Default Status';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SearchItems)
            {
                ApplicationArea = All;
                Caption = 'Search Items';
                ToolTip = 'Search the items matching the selected filter and add them to the store products.';
                Visible = Rec.Code <> '';
                trigger OnAction()
                var
                    NopItemSearch: Page "Nop Item Search";
                begin
                    NopItemSearch.SetFilterCode(Rec.Code);
                    NopItemSearch.Run();
                end;
            }
        }
    }
}
