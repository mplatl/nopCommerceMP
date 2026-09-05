namespace NopCommerceConnector;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Adds items to the store products of a shop (Nop Product selection).
/// The request page allows filtering the items by item fields (No., description, …)
/// and optionally by an item attribute (and its value).
/// Every found item is inserted as a store product of the selected shop.
/// </summary>
report 62150 "Add Store Products"
{
    ApplicationArea = All;
    Caption = 'Add Store Products';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Item; Item)
    {
        RequestFilterHeading = 'Items';
        RequestFilterFields = "No.", Description, "Item Category Code", Blocked;

        trigger OnAfterGetRecord()
        begin
            //attribute filter: the item must have the selected attribute (value)
            if AttrFilterUsed and not ItemHasAttribute(Item."No.") then begin
                SkippedNoAttribute += 1;
                exit;
            end;

            AddStoreProduct(Item."No.", Item.Description);
        end;
    }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Store)
                {
                    Caption = 'Store';

                    field(ShopCode; ShopCode)
                    {
                        Caption = 'Shop Code';
                        TableRelation = "Nop Commerce Shop".Code;
                        ToolTip = 'The shop (store) the found items are added to.';
                    }
                    field(DefaultStatus; DefaultStatus)
                    {
                        Caption = 'Status';
                        ToolTip = 'The status that is set on the added store products. Set to Active to transfer them to nopCommerce.';
                    }
                }
                group(ItemAttributeFilter)
                {
                    Caption = 'Item Attribute Filter';

                    field(AttributeName; AttributeName)
                    {
                        Caption = 'Attribute';
                        ToolTip = 'The name of the item attribute, e.g. "Color".';
                    }
                    field(AttributeValue; AttributeValue)
                    {
                        Caption = 'Attribute Value';
                        ToolTip = 'Only items having this attribute value are added. Leave empty to add all items of the attribute.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            //preselect the shop the report was opened for
            if ShopCode = '' then
                ShopCode := RequestShopCode;

            //add new store products as Active by default
            if DefaultStatus = DefaultStatus::Draft then
                DefaultStatus := DefaultStatus::Active;
        end;
    }

    trigger OnPreReport()
    begin
        Added := 0;
        AlreadyExists := 0;
        SkippedNoAttribute := 0;

        //validate the shop
        if not NopShop.Get(ShopCode) then
            Error(ShopNotFoundErr, ShopCode);

        //resolve the optional attribute filter
        AttrFilterUsed := false;
        ValueFilterUsed := false;

        if AttributeName <> '' then begin
            ItemAttribute.SetRange(Name, AttributeName);
            if not ItemAttribute.FindFirst() then
                Error(AttributeNotFoundErr, AttributeName);

            AttrID := ItemAttribute.ID;
            AttrFilterUsed := true;

            if AttributeValue <> '' then begin
                ItemAttributeValue.SetRange("Attribute ID", AttrID);
                ItemAttributeValue.SetFilter(Value, '%1', AttributeValue);
                if not ItemAttributeValue.FindFirst() then
                    Error(AttributeValueNotFoundErr, AttributeValue, AttributeName);

                AttrValueID := ItemAttributeValue.ID;
                ValueFilterUsed := true;
            end;
        end;
    end;

    trigger OnPostReport()
    begin
        Message(SummaryMsg, Added, ShopCode, AlreadyExists, SkippedNoAttribute);
    end;

    /// <summary>
    /// Sets the shop that is preselected on the request page
    /// </summary>
    /// <param name="ShopCode">The shop code.</param>
    internal procedure SetShopCode(ShopCode: Code[10])
    begin
        RequestShopCode := ShopCode;
    end;

    local procedure ItemHasAttribute(ItemNo: Code[20]): Boolean
    begin
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", AttrID);

        if not ItemAttributeValueMapping.FindFirst() then
            exit(false);

        //when a specific value was chosen, the mapped value must match
        if ValueFilterUsed then
            exit(ItemAttributeValueMapping."Item Attribute Value ID" = AttrValueID);

        exit(true);
    end;

    local procedure AddStoreProduct(ItemNo: Code[20]; ItemDescription: Text[100])
    begin
        NopProduct.SetRange("Shop Code", ShopCode);

        if NopProduct.Get(ShopCode, ItemNo) then
            AlreadyExists += 1
        else begin
            NopProduct."Shop Code" := ShopCode;
            NopProduct."Item No." := ItemNo;
            NopProduct.Description := ItemDescription;
            NopProduct.Status := DefaultStatus;
            NopProduct.Insert();
            Added += 1;
        end;
    end;

    var
        Added: Integer;
        AlreadyExists: Integer;
        SkippedNoAttribute: Integer;
        AttrFilterUsed: Boolean;
        ValueFilterUsed: Boolean;
        AttrID: Integer;
        AttrValueID: Integer;
        RequestShopCode: Code[10];
        ShopCode: Code[10];
        DefaultStatus: enum "Nop Product Status";
        AttributeName: Text[250];
        AttributeValue: Text[250];
        NopShop: Record "Nop Commerce Shop";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        NopProduct: Record "Nop Product";
        ShopNotFoundErr: Label 'Shop "%1" does not exist.', Comment = 'Shown when the shop on the request page does not exist.';
        AttributeNotFoundErr: Label 'Item attribute "%1" was not found.', Comment = 'Shown when the attribute filter does not match any attribute.';
        AttributeValueNotFoundErr: Label 'Attribute value "%1" was not found for attribute "%2".', Comment = 'Shown when the attribute value filter does not match.';
        SummaryMsg: Label 'Store products added to shop %2: %1 added, %3 already existing, %4 items skipped (attribute filter).', Comment = 'Summary shown after the report run.';
}
