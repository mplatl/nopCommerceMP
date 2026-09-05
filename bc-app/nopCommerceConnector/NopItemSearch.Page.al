namespace NopCommerceConnector;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Item search page: shows the items that match a saved filter (item fields + attribute filter)
/// or the current manual filters, and adds them as store products of a shop.
/// The attribute filter uses the standard item attribute search (page "Filter Items by Attribute").
/// </summary>
page 62107 "Nop Item Search"
{
    ApplicationArea = All;
    PageType = List;
    SourceTable = Item;
    Caption = 'nopCommerce Item Search';
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
                field(Blocked; Rec.Blocked)
                {
                    Caption = 'Blocked';
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
                Caption = 'Filter by Attributes';
                ToolTip = 'Search the items with the standard item attribute search.';
                trigger OnAction()
                begin
                    SearchByAttributes();
                end;
            }
            action(AddToStoreProducts)
            {
                ApplicationArea = All;
                Caption = 'Add to Store Products';
                ToolTip = 'Add all currently listed items to the store products of the target shop.';
                trigger OnAction()
                begin
                    AddFilteredItemsToStoreProducts();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if FilterCode <> '' then
            if Filter.Get(FilterCode) then begin
                ShopCode := Filter."Shop Code";
                DefaultStatus := Filter."Default Status";
                ApplySavedFilter(Filter);
            end;
    end;

    /// <summary>
    /// Sets the target shop (opened from a shop card/list)
    /// </summary>
    internal procedure SetShopCode(NewShopCode: Code[10])
    begin
        ShopCode := NewShopCode;
        if DefaultStatus = DefaultStatus::Draft then
            DefaultStatus := DefaultStatus::Active;
    end;

    /// <summary>
    /// Sets the saved filter that is applied when the page opens
    /// </summary>
    internal procedure SetFilterCode(NewFilterCode: Code[10])
    begin
        FilterCode := NewFilterCode;
    end;

    local procedure ApplySavedFilter(Filter: Record "Nop Product Filter")
    var
        NopStoreProducts: Codeunit "Nop Store Products";
        AttributeNumbers: Text;
    begin
        Rec.FilterGroup(0);

        //attribute filter: only the items matching the standard attribute logic are shown
        AttributeNumbers := NopStoreProducts.GetAttributeItemNumbers(Filter."Attribute Filter");
        if AttributeNumbers <> '' then
            Rec.SetFilter("No.", AttributeNumbers)
        else begin
            if Filter."Item No. Filter" <> '' then
                Rec.SetFilter("No.", Filter."Item No. Filter");
        end;

        if Filter."Description Filter" <> '' then
            Rec.SetFilter(Description, Filter."Description Filter");
        if Filter."Item Category Filter" <> '' then
            Rec.SetFilter("Item Category Code", Filter."Item Category Filter");
    end;

    local procedure SearchByAttributes()
    var
        NopStoreProducts: Codeunit "Nop Store Products";
        TempFilter: Record "Filter Item Attributes Buffer" temporary;
        CriteriaText: Text[250];
        AttributeNumbers: Text;
        NopFilteredItems: Page "Nop Filtered Items";
    begin
        if ShopCode = '' then
            Error(ShopNotSetErr);

        //run the standard attribute search dialog
        if not NopStoreProducts.RunAttributeSearchDialog(TempFilter) then
            exit;

        CriteriaText := NopStoreProducts.GetCriteriaText(TempFilter);
        AttributeNumbers := NopStoreProducts.GetAttributeItemNumbers(CriteriaText);
        if AttributeNumbers = '' then begin
            Message(NoItemsFoundMsg);
            exit;
        end;

        //show the matching items in the result page and add them there
        NopFilteredItems.SetItemNumbers(AttributeNumbers);
        NopFilteredItems.SetShopCode(ShopCode);
        NopFilteredItems.SetDefaultStatus(DefaultStatus);
        NopFilteredItems.Run();
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
                if Rec."No." <> '' then begin
                    NopStoreProducts.AddItem(ShopCode, Rec."No.", Rec.Description, DefaultStatus, Added, AlreadyExists);
                    if Added then
                        AddedCount += 1;
                    if AlreadyExists then
                        ExistingCount += 1;
                end;
            until Rec.Next() = 0;

        Message(SummaryMsg, ShopCode, AddedCount, ExistingCount);
    end;

    var
        ShopCode: Code[10];
        FilterCode: Code[10];
        DefaultStatus: enum "Nop Product Status";
        Filter: Record "Nop Product Filter";
        ShopNotSetErr: Label 'Open this item search from a shop ("Search & Add Items") or from a saved filter first, so that the target shop is known.';
        ShopNotFoundErr: Label 'Shop "%1" does not exist.';
        NoItemsFoundMsg: Label 'No items match the selected attributes.';
        SummaryMsg: Label 'Items added to shop %1: %2 added, %3 already existing.';
}
