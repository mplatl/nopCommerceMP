namespace NopCommerceConnector;

using Microsoft.Inventory.Item.Attribute;

/// <summary>
/// Card to create and edit a saved item search filter (with code).
/// The filter combines item filters (No., description, item category) with an optional
/// item attribute (and value) and targets one shop with a default status.
/// </summary>
page 62106 "Nop Product Filter"
{
    ApplicationArea = All;
    Caption = 'nopCommerce Product Filter';
    PageType = Card;
    SourceTable = "Nop Product Filter";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
            }
            group(Target)
            {
                Caption = 'Target';

                field("Shop Code"; Rec."Shop Code")
                {
                    Caption = 'Shop Code';
                }
                field("Default Status"; Rec."Default Status")
                {
                    Caption = 'Default Status';
                }
            }
            group(ItemFilter)
            {
                Caption = 'Item Filter';

                field("Item No. Filter"; Rec."Item No. Filter")
                {
                    Caption = 'Item No. Filter';
                }
                field("Description Filter"; Rec."Description Filter")
                {
                    Caption = 'Description Filter';
                }
                field("Item Category Filter"; Rec."Item Category Filter")
                {
                    Caption = 'Item Category Filter';
                }
            }
            group(AttributeFilter)
            {
                Caption = 'Attribute Filter';

                field("Attribute Name"; Rec."Attribute Name")
                {
                    Caption = 'Attribute';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemAttribute: Record "Item Attribute";
                        ItemAttributes: Page "Item Attributes";
                    begin
                        ItemAttributes.LookupMode := true;
                        ItemAttributes.SetTableView(ItemAttribute);
                        if ItemAttributes.RunModal() = Action::LookupOK then begin
                            ItemAttributes.GetRecord(ItemAttribute);
                            Rec."Attribute Name" := ItemAttribute.Name;
                            Rec."Attribute Value" := '';
                        end;
                        exit(true);
                    end;
                }
                field("Attribute Value"; Rec."Attribute Value")
                {
                    Caption = 'Attribute Value';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemAttribute: Record "Item Attribute";
                        ItemAttributeValue: Record "Item Attribute Value";
                        ItemAttributeValues: Page "Item Attribute Values";
                        AttributeID: Integer;
                    begin
                        if Rec."Attribute Name" = '' then begin
                            Message('Select an attribute first before choosing an attribute value.');
                            exit(true);
                        end;
                        ItemAttribute.SetRange(Name, Rec."Attribute Name");
                        if not ItemAttribute.FindFirst() then begin
                            Error('Item attribute "%1" was not found.', Rec."Attribute Name");
                            exit(true);
                        end;
                        AttributeID := ItemAttribute.ID;
                        ItemAttributeValue.SetRange("Attribute ID", AttributeID);
                        ItemAttributeValues.LookupMode := true;
                        ItemAttributeValues.SetTableView(ItemAttributeValue);
                        if ItemAttributeValues.RunModal() = Action::LookupOK then begin
                            ItemAttributeValues.GetRecord(ItemAttributeValue);
                            Rec."Attribute Value" := ItemAttributeValue.Value;
                        end;
                        exit(true);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SearchItems)
            {
                ApplicationArea = All;
                Caption = 'Search Items';
                ToolTip = 'Search the items matching this filter and add them to the store products.';
                trigger OnAction()
                var
                    NopItemSearch: Page "Nop Item Search";
                begin
                    NopItemSearch.SetFilterCode(Rec.Code);
                    NopItemSearch.Run();
                end;
            }
            action(StoreProducts)
            {
                ApplicationArea = All;
                Caption = 'Store Products';
                ToolTip = 'Open the store products of the target shop.';
                trigger OnAction()
                var
                    NopCommerceProducts: Page "Nop Commerce Products";
                begin
                    NopCommerceProducts.SetShopCode(Rec."Shop Code");
                    NopCommerceProducts.Run();
                end;
            }
        }
    }
}
