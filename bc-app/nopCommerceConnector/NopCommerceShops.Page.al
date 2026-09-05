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
}
