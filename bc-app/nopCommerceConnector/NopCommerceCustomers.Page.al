namespace NopCommerceConnector;

/// <summary>
/// List of the customer logins (Debitoren-Logins) per shop ("Nop Customer Login").
/// Opened via the "Customers" action of the shop (Setup/card and Shops list) —
/// the page is filtered to the shop and new records get the shop code automatically.
/// Several logins per customer (Debitor) are possible (one row per login/e-mail).
/// The initial password is displayed masked; it is set per row via "Set Initial
/// Password" and transferred per row or for all Draft rows ("Push Login(s)").
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
                field(PasswordMasked; PasswordMaskedDisplay)
                {
                    Caption = 'Initial Password';
                    Editable = false;
                    ToolTip = 'Initial password for the login in the shop (shown masked; set per row via "Set Initial Password").';
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
            action(SetInitialPassword)
            {
                Caption = 'Set Initial Password';
                ToolTip = 'Sets the initial password that is used when the account of this login is created in the shop (dialog only, masked display).';
                ApplicationArea = All;
                trigger OnAction()
                var
                    Login: Record "Nop Customer Login";
                    PwPage: Page "Nop Login Password";
                begin
                    if Rec."E-mail" = '' then
                        Error('Select a customer login first.');
                    PwPage.SetEmail(Rec."E-mail");
                    PwPage.RunModal();
                    if not PwPage.WasOkPressed() then
                        exit;
                    if not Login.Get(Rec."Shop Code", Rec."Customer No.", Rec."E-mail") then
                        Error('The selected customer login does not exist anymore.');
                    Login."Initial Password" := PwPage.GetPassword();
                    Login.Modify();
                    Rec."Initial Password" := Login."Initial Password";
                    if Login."Initial Password" <> '' then
                        PasswordMaskedDisplay := '********'
                    else
                        PasswordMaskedDisplay := '';
                end;
            }
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
        PasswordMaskedDisplay: Text;

    trigger OnOpenPage()
    begin
        //opened from a store: filter by shop, opened from a customer (Debitor): filter by customer
        if NopCustomerNo <> '' then begin
            Rec.SetRange("Customer No.", NopCustomerNo);
        end else
            if NopShopCode <> '' then
                Rec.SetRange("Shop Code", NopShopCode);
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Initial Password" <> '' then
            PasswordMaskedDisplay := '********'
        else
            PasswordMaskedDisplay := '';
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
