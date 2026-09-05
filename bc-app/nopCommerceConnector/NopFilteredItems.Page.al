namespace NopCommerceConnector;

using Microsoft.Inventory.Item;

/// <summary>
/// Result list of the standard item attribute search. The item numbers were determined by the
/// standard attribute logic; the list only shows the matching items and offers to add them
/// as store products of the target shop.
/// </summary>
page 62109 "Nop Filtered Items"
{
    ApplicationArea = All;
    PageType = List;
    SourceTable = Item;
    Caption = 'Filtered Items (Attributes)';
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            repeater(Items)
            {
                field("No."; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    Caption = 'Item Category Code';
                }
                field(Inventory; Rec.Inventory)
                {
                    Caption = 'Inventory';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    Caption = 'Unit Price';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddToStoreProducts)
            {
                ApplicationArea = All;
                Caption = 'Add to Store Products';
                ToolTip = 'Add all listed items to the store products of the target shop.';
                trigger OnAction()
                begin
                    AddFilteredItemsToStoreProducts();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if ItemNumbers <> '' then
            Rec.SetFilter("No.", ItemNumbers);
    end;

    internal procedure SetItemNumbers(NewItemNumbers: Text)
    begin
        ItemNumbers := NewItemNumbers;
    end;

    internal procedure SetShopCode(NewShopCode: Code[10])
    begin
        ShopCode := NewShopCode;
    end;

    internal procedure SetDefaultStatus(NewDefaultStatus: enum "Nop Product Status")
    begin
        DefaultStatus := NewDefaultStatus;
    end;

    local procedure AddFilteredItemsToStoreProducts()
    var
        NopStoreProducts: Codeunit "Nop Store Products";
        Added: Boolean;
        AlreadyExists: Boolean;
        AddedCount: Integer;
        ExistingCount: Integer;
    begin
        if ShopCode = '' then
            Error(ShopNotSetErr);

        if not NopStoreProducts.ShopExists(ShopCode) then
            Error(ShopNotFoundErr, ShopCode);

        AddedCount := 0;
        ExistingCount := 0;

        if Rec.FindSet() then
            repeat
                NopStoreProducts.AddItem(ShopCode, Rec."No.", Rec.Description, DefaultStatus, Added, AlreadyExists);
                if Added then
                    AddedCount += 1;
                if AlreadyExists then
                    ExistingCount += 1;
            until Rec.Next() = 0;

        Message(SummaryMsg, ShopCode, AddedCount, ExistingCount);
    end;

    var
        ItemNumbers: Text;
        ShopCode: Code[10];
        DefaultStatus: enum "Nop Product Status";
        ShopNotSetErr: Label 'Open this attribute search from a shop ("Search & Add Items") or from a saved filter first, so that the target shop is known.';
        ShopNotFoundErr: Label 'Shop "%1" does not exist.';
        SummaryMsg: Label 'Items added to shop %1: %2 added, %3 already existing.';
}
