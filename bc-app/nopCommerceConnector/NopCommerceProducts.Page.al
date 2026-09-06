namespace NopCommerceConnector;

/// <summary>
/// List of the products that are managed for a nopCommerce shop.
/// Only records listed here are exported — nothing is exported automatically.
/// </summary>
page 62101 "Nop Commerce Products"
{
    ApplicationArea = All;
    PageType = List;
    SourceTable = "Nop Product";
    Caption = 'nopCommerce Products';
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Products)
            {
                // no "Shop Code" column: the page is opened filtered from the shop card
                // (Setup -> Products / Search & Add Items) and always belongs to one shop.
                field("Item No."; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field("Nop Product Id"; Rec."Nop Product Id")
                {
                    Caption = 'nopCommerce Product ID';
                }
                field("Synchronized Date"; Rec."Synchronized Date")
                {
                    Caption = 'Synchronized Date';
                }
                field("Last Sync Error"; Rec."Last Sync Error")
                {
                    Caption = 'Last Sync Error';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        //show only the products of the shop the page was opened for (if any)
        if NopShopCode <> '' then
            Rec.SetRange("Shop Code", NopShopCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        //new rows belong to the shop the page was opened for (if any)
        if NopShopCode <> '' then
            Rec."Shop Code" := NopShopCode;
    end;

    var
        NopShopCode: Code[10];

    /// <summary>
    /// Opens the product list filtered to a single shop.
    /// </summary>
    /// <param name="ShopCode">The shop to filter by (empty shows all shops).</param>
    internal procedure SetShopCode(ShopCode: Code[10])
    begin
        NopShopCode := ShopCode;
    end;
}
