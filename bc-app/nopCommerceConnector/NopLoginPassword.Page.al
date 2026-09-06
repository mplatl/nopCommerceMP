namespace NopCommerceConnector;

/// <summary>
/// Sets the initial password of one customer login ("Nop Customer Login"). It is opened
/// as the AssistEdit dialog of the "Initial Password" column on the Customers page and
/// behaves like the standard password dialogs (masked input field, standard OK/Cancel,
/// no custom OK action): the password is stored on the login row when the dialog is
/// confirmed with the standard OK action (ACTION::OK in OnQueryClosePage).
/// </summary>
page 62123 "Nop Login Password"
{
    ApplicationArea = All;
    Caption = 'Set Initial Password';
    DataCaptionExpression = Rec."E-mail";
    PageType = StandardDialog;
    SourceTable = "Nop Customer Login";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Initial password of the shop account (used when the account is created in the shop).';
                field("Initial Password"; NewPassword)
                {
                    Caption = 'Initial Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Initial password of the shop account.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if LoginEmail = '' then
            Error('Select a customer login first.');
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Login: Record "Nop Customer Login";
    begin
        if CloseAction = ACTION::OK then begin
            if not Login.Get(ShopCode, CustomerNo, LoginEmail) then
                Error('The selected customer login does not exist anymore.');
            Login."Initial Password" := NewPassword;
            Login.Modify();
        end;
        exit(true);
    end;

    var
        ShopCode: Code[10];
        CustomerNo: Code[20];
        LoginEmail: Text[250];
        NewPassword: Text[250];

    procedure SetLogin(Login: Record "Nop Customer Login")
    begin
        ShopCode := Login."Shop Code";
        CustomerNo := Login."Customer No.";
        LoginEmail := Login."E-mail";
    end;
}
