namespace NopCommerceConnector;

/// <summary>
/// List of the categories of a shop ("Nop Category"). Opened via the "Categories"
/// action of the shop (Setup/card and Shops list); the page is filtered to the shop.
/// Categories are defined per shop (no 1:1 match with Business Central categories)
/// and can have parent categories - the hierarchy is built like in nopCommerce.
/// </summary>
page 62132 "Nop Commerce Categories"
{
    ApplicationArea = All;
    Caption = 'nopCommerce Categories';
    PageType = List;
    SourceTable = "Nop Category";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Categories)
            {
                field(Code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field("Parent Code"; Rec."Parent Code")
                {
                    Caption = 'Parent Category';
                    ToolTip = 'Parent category of this category (same shop). Categories can be nested like in nopCommerce; an empty value means a top-level category.';
                }
                field(ParentName; ParentNameDisplay)
                {
                    Caption = 'Parent Name';
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
            }
        }
    }

    var
        NopShopCode: Code[10];
        ParentNameDisplay: Text;

    trigger OnOpenPage()
    begin
        if NopShopCode <> '' then
            Rec.SetRange("Shop Code", NopShopCode);
    end;

    trigger OnAfterGetRecord()
    var
        Parent: Record "Nop Category";
    begin
        if Rec."Parent Code" <> '' then begin
            Parent.SetRange("Shop Code", Rec."Shop Code");
            Parent.SetRange(Code, Rec."Parent Code");
            if Parent.FindFirst() then
                ParentNameDisplay := Parent.Name
            else
                ParentNameDisplay := '';
        end else
            ParentNameDisplay := '';
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if NopShopCode <> '' then
            Rec."Shop Code" := NopShopCode;
    end;

    procedure SetShopCode(ShopCode: Code[10])
    begin
        NopShopCode := ShopCode;
    end;
}
