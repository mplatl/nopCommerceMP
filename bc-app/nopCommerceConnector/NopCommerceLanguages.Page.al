namespace NopCommerceConnector;

/// <summary>
/// List page of the nopCommerce languages per shop ("Nop Language").
/// Opened via the "Languages" action of the shop (Setup/card and Shops list)
/// and of the role center. The first language record of a shop is suggested
/// as default language.
/// </summary>
page 62112 "Nop Commerce Languages"
{
    ApplicationArea = All;
    Caption = 'nopCommerce Languages';
    PageType = List;
    SourceTable = "Nop Language";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Languages)
            {
                field("Shop Code"; Rec."Shop Code")
                {
                    Caption = 'Shop Code';
                }
                field("Language ID"; Rec."Language ID")
                {
                    Caption = 'Language ID';
                }
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field("Language Culture"; Rec."Language Culture")
                {
                    Caption = 'Language Culture';
                }
                field(Published; Rec.Published)
                {
                    Caption = 'Published';
                }
                field("Display Order"; Rec."Display Order")
                {
                    Caption = 'Display Order';
                }
                field("Is Default"; Rec."Is Default")
                {
                    Caption = 'Is Default';
                }
                field("Synchronized Date"; Rec."Synchronized Date")
                {
                    Caption = 'Synchronized Date';
                    Editable = false;
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

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        NopLanguage: Record "Nop Language";
    begin
        Rec."Shop Code" := NopShopCode;
        NopLanguage.SetRange("Shop Code", NopShopCode);
        NopLanguage.SetRange("Is Default", true);
        if not NopLanguage.FindFirst() then
            Rec."Is Default" := true;
    end;

    procedure SetShopCode(ShopCode: Code[10])
    begin
        NopShopCode := ShopCode;
    end;
}
