namespace NopCommerceConnector;

/// <summary>
/// Represents a category of a nopCommerce shop that Business Central manages.
/// Categories are defined per shop and are NOT matched 1:1 with the Business Central
/// item categories - the shop owner structures the shop catalog independently.
/// Like in nopCommerce a category can have a parent category ("Parent Code"), which
/// forms a hierarchy of any depth; the parent must belong to the same shop. Cycles
/// and self-references are rejected, and a category that still has subcategories
/// cannot be deleted or renamed (keys referenced by children).
/// </summary>
table 62130 "Nop Category"
{
    Caption = 'nopCommerce Category';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shop Code"; Code[10])
        {
            Caption = 'Shop Code';
            DataClassification = CustomerContent;
            TableRelation = "Nop Commerce Shop".Code;
            NotBlank = true;
            ToolTip = 'Shop in nopCommerce to which this category belongs.';
        }
        field(2; Code; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Key of the category within the shop.';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Name of the category as it is shown in the shop.';
        }
        field(4; "Parent Code"; Code[20])
        {
            Caption = 'Parent Category';
            DataClassification = CustomerContent;
            TableRelation = "Nop Category".Code where("Shop Code" = field("Shop Code"));
            ToolTip = 'Parent category of this category (same shop). Categories can be nested like in nopCommerce; an empty value means a top-level category.';
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Description text of the category.';
        }
        field(6; Status; enum "Nop Category Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(7; "Nop Category Id"; BigInteger)
        {
            Caption = 'nopCommerce Category ID';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(8; "Synchronized Date"; DateTime)
        {
            Caption = 'Synchronized Date';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(9; "Last Sync Error"; Text[250])
        {
            Caption = 'Last Sync Error';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PrimaryKey; "Shop Code", Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Shop Code", Code, Name, "Parent Code")
        {
        }
    }

    trigger OnInsert()
    begin
        ValidateHierarchy();
    end;

    trigger OnModify()
    begin
        ValidateHierarchy();
    end;

    trigger OnRename()
    begin
        if HasChildren() then
            Error('Category "%1" cannot be renamed because it has subcategories. Rename the subcategories first.', Code);
    end;

    trigger OnDelete()
    begin
        if HasChildren() then
            Error('Category "%1" cannot be deleted because it has subcategories. Delete or move the subcategories first.', Code);
    end;

    local procedure ValidateHierarchy()
    var
        Category: Record "Nop Category";
        CurrentParent: Code[20];
        Steps: Integer;
    begin
        if "Parent Code" = '' then
            exit;

        if "Parent Code" = Code then
            Error('Category "%1" cannot be its own parent.', Code);

        Category.SetRange("Shop Code", "Shop Code");
        Category.SetRange(Code, "Parent Code");
        if not Category.FindFirst() then
            Error('The parent category "%1" does not exist in shop "%2".', "Parent Code", "Shop Code");

        //walk the ancestors upwards; if we ever reach the category itself, the hierarchy has a cycle
        CurrentParent := Category."Parent Code";
        Steps := 0;
        while CurrentParent <> '' do begin
            Steps += 1;
            if Steps > 50 then
                Error('The category hierarchy of "%1" is too deep or contains a cycle.', Code);

            Category.SetRange("Shop Code", "Shop Code");
            Category.SetRange(Code, CurrentParent);
            if not Category.FindFirst() then
                Error('The parent category "%1" does not exist in shop "%2".', CurrentParent, "Shop Code");

            if Category.Code = Code then
                Error('Category "%1" would create a cycle in the category hierarchy.', Code);

            CurrentParent := Category."Parent Code";
        end;
    end;

    local procedure HasChildren(): Boolean
    var
        Category: Record "Nop Category";
    begin
        Category.SetRange("Shop Code", "Shop Code");
        Category.SetRange("Parent Code", Code);
        exit(Category.FindFirst());
    end;
}
