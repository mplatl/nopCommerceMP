namespace NopCommerceConnector;

/// <summary>
/// Cue part ("Stapel") for the nopCommerce role center: shows the number of
/// connected shops; clicking the tile opens the "Nop Commerce Shops" list.
/// </summary>
page 62121 "Nop Commerce Shop Cue"
{
    ApplicationArea = All;
    Caption = 'Shops';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Nop Commerce Cue";

    layout
    {
        area(content)
        {
            cuegroup(Shops)
            {
                Caption = 'Shops';
                field(ShopCount; Rec."Shop Count")
                {
                    Caption = 'Shops';
                    DrillDownPageID = "Nop Commerce Shops";
                    ToolTip = 'Specifies the number of connected nopCommerce shops. Select to open the list of shops.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get('') then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert();
        end;
        Rec.CalcFields("Shop Count");
    end;
}
