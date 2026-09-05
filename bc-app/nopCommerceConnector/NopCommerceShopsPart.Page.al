namespace NopCommerceConnector;

/// <summary>
/// List part of the nopCommerce shops, used on the "nopCommerce Admin" role center.
/// </summary>
page 62103 "Nop Commerce Shops Part"
{
    ApplicationArea = All;
    Caption = 'nopCommerce Shops';
    PageType = ListPart;
    SourceTable = "Nop Commerce Shop";

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
                field(Enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
                }
                field("Sync Products"; Rec."Sync Products")
                {
                    Caption = 'Sync Products';
                }
            }
        }
    }
}
