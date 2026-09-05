namespace NopCommerceConnector;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Item search page that shows the items matching a saved filter (or the current manual filters)
/// and adds them as store products of a shop. Open it from a shop ("Search &amp; Add Items") or
/// from a saved filter ("Search Items") - the target shop and the default status are then preset.
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
    begin
        Rec.FilterGroup(0);

        if Filter."Item No. Filter" <> '' then
            Rec.SetFilter("No.", Filter."Item No. Filter");
        if Filter."Description Filter" <> '' then
            Rec.SetFilter(Description, Filter."Description Filter");
        if Filter."Item Category Filter" <> '' then
            Rec.SetFilter("Item Category Code", Filter."Item Category Filter");

        //optional attribute filter - replaces the item number filter with the matching item numbers
        if Filter."Attribute Name" <> '' then begin
            AttributeNumbers := BuildAttributeItemNumbers(Filter."Attribute Name", Filter."Attribute Value");
            if AttributeNumbers <> '' then
                Rec.SetFilter("No.", AttributeNumbers);
        end;
    end;

    local procedure BuildAttributeItemNumbers(AttributeName: Text; AttributeValue: Text): Text
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemNumbers: Text;
    begin
        if AttributeName = '' then
            exit('');

        ItemAttribute.SetRange(Name, AttributeName);
        if not ItemAttribute.FindFirst() then
            exit('');

        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);

        if AttributeValue <> '' then begin
            ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
            ItemAttributeValue.SetFilter(Value, '%1', AttributeValue);
            if not ItemAttributeValue.FindFirst() then
                exit('');
            ItemAttributeValueMapping.SetRange("Item Attribute Value ID", ItemAttributeValue.ID);
        end;

        if ItemAttributeValueMapping.FindSet() then
            repeat
                if ItemAttributeValueMapping."No." <> '' then begin
                    if StrLen(ItemNumbers) + StrLen(ItemAttributeValueMapping."No.") + 1 > 2000 then
                        exit(ItemNumbers);
                    if ItemNumbers = '' then
                        ItemNumbers := ItemAttributeValueMapping."No."
                    else
                        ItemNumbers := ItemNumbers + '|' + ItemAttributeValueMapping."No.";
                end;
            until ItemAttributeValueMapping.Next() = 0;

        exit(ItemNumbers);
    end;

    local procedure AddFilteredItemsToStoreProducts()
    var
        NopShop: Record "Nop Commerce Shop";
        NopProduct: Record "Nop Product";
        Added: Integer;
        AlreadyExists: Integer;
    begin
        if ShopCode = '' then
            Error(ShopNotSetErr);

        if not NopShop.Get(ShopCode) then
            Error(ShopNotFoundErr, ShopCode);

        Added := 0;
        AlreadyExists := 0;

        if Rec.FindSet() then
            repeat
                if Rec."No." <> '' then begin
                    NopProduct.SetRange("Shop Code", ShopCode);
                    if NopProduct.Get(ShopCode, Rec."No.") then
                        AlreadyExists += 1
                    else begin
                        NopProduct."Shop Code" := ShopCode;
                        NopProduct."Item No." := Rec."No.";
                        NopProduct.Description := Rec.Description;
                        NopProduct.Status := DefaultStatus;
                        NopProduct.Insert();
                        Added += 1;
                    end;
                end;
            until Rec.Next() = 0;

        Message(SummaryMsg, ShopCode, Added, AlreadyExists);
    end;

    var
        ShopCode: Code[10];
        FilterCode: Code[10];
        DefaultStatus: enum "Nop Product Status";
        AttributeNumbers: Text;
        Filter: Record "Nop Product Filter";
        ShopNotSetErr: Label 'Open this item search from a shop ("Search & Add Items") or from a saved filter first, so that the target shop is known.';
        ShopNotFoundErr: Label 'Shop "%1" does not exist.';
        SummaryMsg: Label 'Items added to shop %1: %2 added, %3 already existing.';
}
