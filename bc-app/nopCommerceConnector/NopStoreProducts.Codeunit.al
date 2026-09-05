namespace NopCommerceConnector;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Shared logic to add items as store products of a shop and to run the standard item
/// attribute search (same dialog and logic as the standard item list "Filter by Attributes").
/// </summary>
codeunit 62110 "Nop Store Products"
{
    /// <summary>
    /// Checks whether the shop exists
    /// </summary>
    internal procedure ShopExists(ShopCode: Code[10]): Boolean
    var
        NopShop: Record "Nop Commerce Shop";
    begin
        exit(NopShop.Get(ShopCode));
    end;

    /// <summary>
    /// Adds one item as store product of the shop (skips duplicates, key = shop + item)
    /// </summary>
    internal procedure AddItem(ShopCode: Code[10]; ItemNo: Code[20]; Description: Text[100];
        DefaultStatus: enum "Nop Product Status"; var Added: Boolean; var AlreadyExists: Boolean)
    var
        NopProduct: Record "Nop Product";
    begin
        Added := false;
        AlreadyExists := false;

        if ItemNo = '' then
            exit;

        NopProduct.SetRange("Shop Code", ShopCode);
        if NopProduct.Get(ShopCode, ItemNo) then
            AlreadyExists := true
        else begin
            NopProduct."Shop Code" := ShopCode;
            NopProduct."Item No." := ItemNo;
            NopProduct.Description := Description;
            NopProduct.Status := DefaultStatus;
            NopProduct.Insert();
            Added := true;
        end;
    end;

    /// <summary>
    /// Runs the standard item attribute search dialog (page "Filter Items by Attribute").
    /// On OK the passed temporary buffer contains the chosen criteria rows.
    /// </summary>
    internal procedure RunAttributeSearchDialog(var TempFilter: Record "Filter Item Attributes Buffer" temporary): Boolean
    var
        FilterPageID: Integer;
    begin
        FilterPageID := PAGE::"Filter Items by Attribute";
        if PAGE.RunModal(FilterPageID, TempFilter) <> Action::LookupOK then
            exit(false);
        exit(not TempFilter.IsEmpty());
    end;

    /// <summary>
    /// Builds the criteria text (Attribute=Value, entries separated by "|") from the buffer rows
    /// </summary>
    internal procedure GetCriteriaText(var TempFilter: Record "Filter Item Attributes Buffer" temporary): Text[250]
    var
        CriteriaText: Text[250];
    begin
        if TempFilter.FindSet() then
            repeat
                if (TempFilter.Attribute <> '') and (TempFilter.Value <> '') then begin
                    if StrLen(CriteriaText) + StrLen(TempFilter.Attribute) + StrLen(TempFilter.Value) + 3 > 250 then
                        exit(CriteriaText);
                    if CriteriaText = '' then
                        CriteriaText := StrSubstNo('%1=%2', TempFilter.Attribute, TempFilter.Value)
                    else
                        CriteriaText := StrSubstNo('%1|%2=%3', CriteriaText, TempFilter.Attribute, TempFilter.Value);
                end;
            until TempFilter.Next() = 0;

        exit(CriteriaText);
    end;

    /// <summary>
    /// Converts the stored attribute filter text (Attribute=Value separated by "|")
    /// into the matching item numbers by running the standard item attribute management logic
    /// (the resulting text can be applied via SetFilter("No.", …)).
    /// </summary>
    internal procedure GetAttributeItemNumbers(AttributeFilter: Text): Text
    var
        TempFilter: Record "Filter Item Attributes Buffer" temporary;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        TempFilteredItem: Record Item temporary;
        ParameterCount: Integer;
        Entry: Text;
        SeparatorPos: Integer;
        Remaining: Text;
    begin
        if AttributeFilter = '' then
            exit('');

        Remaining := AttributeFilter;
        while Remaining <> '' do begin
            SeparatorPos := StrPos(Remaining, '|');
            if SeparatorPos = 0 then begin
                Entry := Remaining;
                Remaining := '';
            end else begin
                Entry := CopyStr(Remaining, 1, SeparatorPos - 1);
                Remaining := CopyStr(Remaining, SeparatorPos + 1);
            end;

            SeparatorPos := StrPos(Entry, '=');
            if SeparatorPos > 0 then begin
                TempFilter.Attribute := CopyStr(Entry, 1, SeparatorPos - 1);
                TempFilter.Value := CopyStr(Entry, SeparatorPos + 1);
                TempFilter.Insert();
            end;
        end;

        if TempFilter.IsEmpty() then
            exit('');

        ItemAttributeManagement.FindItemsByAttributes(TempFilter, TempFilteredItem);

        exit(ItemAttributeManagement.GetItemNoFilterText(TempFilteredItem, ParameterCount));
    end;
}
