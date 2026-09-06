namespace NopCommerceConnector;

using Microsoft.Inventory.Item;

/// <summary>
/// Represents an item of a shop that is (candidate to be) exported to nopCommerce.
/// Only items that have a record here are ever pushed to nopCommerce —
/// this is the mechanism that prevents exporting the whole item catalog
/// (mirrors "Shopfy Product" of the Microsoft Shopify Connector).
/// </summary>
table 62101 "Nop Product"
{
    Caption = 'nopCommerce Product';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shop Code"; Code[10])
        {
            Caption = 'Shop Code';
            DataClassification = CustomerContent;
            TableRelation = "Nop Commerce Shop".Code;
            NotBlank = true;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(4; "Status"; enum "Nop Product Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(5; "Nop Product Id"; BigInteger)
        {
            Caption = 'nopCommerce Product ID';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(6; "Synchronized Date"; DateTime)
        {
            Caption = 'Synchronized Date';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(7; "Last Sync Error"; Text[250])
        {
            Caption = 'Last Sync Error';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Shop Code", "Item No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        Item: Record Item;
    begin
        //copy the item description to the selection row when it was not entered manually
        if Description = '' then
            if Item.Get(Item."No.", "Item No.") then
                Description := Item.Description;
    end;

    trigger OnDelete()
    var
        NopCommerceMgt: Codeunit "Nop Commerce Mgt.";
    begin
        //Deleting an active store product also removes (unpublishes) the product in the
        //nopCommerce store, otherwise it would remain visible although it is no longer
        //managed here. If the nopCommerce call fails, the deletion is aborted and the
        //row stays (see "Last Sync Error" flow / status Archived for the manual variant).
        if Status = "Nop Product Status"::Active then
            NopCommerceMgt.RemoveProductInNop(Rec);
    end;
}
