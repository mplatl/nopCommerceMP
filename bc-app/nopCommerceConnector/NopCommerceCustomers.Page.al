namespace NopCommerceConnector;

/// <summary>
/// List of the customer logins (Debitoren-Logins) per shop ("Nop Customer Login").
/// Opened via the "Customers" action of the shop (Setup/card and Shops list) —
/// the page is filtered to the shop and new records get the shop code automatically.
/// Several logins per customer (Debitor) are possible (one row per login/e-mail).
/// The "Initial Password" column is displayed masked (like the standard password
/// fields) and is entered/changed via the AssistEdit button of the row.
/// </summary>
page 62122 "Nop Commerce Customers"
{
    ApplicationArea = All;
    Caption = 'nopCommerce Customers';
    PageType = List;
    SourceTable = "Nop Customer Login";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Customers)
            {
                field("Shop Code"; Rec."Shop Code")
                {
                    Caption = 'Shop Code';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field("E-mail"; Rec."E-mail")
                {
                    Caption = 'E-mail';
                }
                field("Initial Password"; Rec."Initial Password")
                {
                    Caption = 'Initial Password';
                    Editable = false;
                    ExtendedDatatype = Masked;
                    AssistEdit = true;
                    ToolTip = 'Initial password of the login in the shop - displayed masked; set or change it with the AssistEdit button.';
                    trigger OnAssistEdit()
                    var
                        PwPage: Page "Nop Login Password";
                    begin
                        PwPage.SetLogin(Rec);
                        PwPage.RunModal();
                    end;
                }
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                }
                field("Nop Customer Id"; Rec."Nop Customer Id")
                {
                    Caption = 'nopCommerce Customer Id';
                }
                field("Synchronized Date"; Rec."Synchronized Date")
                {
                    Caption = 'Synchronized Date';
                    Editable = false;
                }
                field("Last Sync Error"; Rec."Last Sync Error")
                {
                    Caption = 'Last Sync Error';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PushLogin)
            {
                Caption = 'Push Login';
                ToolTip = 'Transfers this single login to the shop: creates the account or, if the e-mail already exists in the shop, synchronizes the nopCommerce customer id back to Business Central.';
                ApplicationArea = All;
                trigger OnAction()
                var
                    NopCustomerSync: Codeunit "Nop Commerce Mgt.";
                begin
                    NopCustomerSync.PushCustomerLoginRow(Rec);
                end;
            }
        }
    }

    var
        NopShopCode: Code[10];
        NopCustomerNo: Code[20];

    trigger OnOpenPage()
    begin
        //opened from a store: filter by shop, opened from a customer (Debitor): filter by customer
        if NopCustomerNo <> '' then begin
            Rec.SetRange("Customer No.", NopCustomerNo);
        end else
            if NopShopCode <> '' then
                Rec.SetRange("Shop Code", NopShopCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if NopCustomerNo = '' then
            Rec."Shop Code" := NopShopCode;
        Rec.Status := "Nop Customer Status"::Draft;
    end;

    procedure SetShopCode(ShopCode: Code[10])
    begin
        NopShopCode := ShopCode;
    end;

    procedure SetCustomerNo(CustomerNo: Code[20])
    begin
        NopCustomerNo := CustomerNo;
    end;
}
