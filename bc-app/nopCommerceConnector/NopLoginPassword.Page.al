namespace NopCommerceConnector;

/// <summary>
/// Modal dialog that sets the initial password of one customer login ("Nop Customer Login").
/// The password is used when the account is created in the shop and is stored only on the
/// login row; the Customers page never shows it in plain text (masked display).
/// </summary>
page 62123 "Nop Login Password"
{
    ApplicationArea = All;
    Caption = 'Set Initial Password';
    PageType = Card;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Email; LoginEmail)
                {
                    Caption = 'E-mail';
                    Editable = false;
                }
                field("Initial Password"; NewPassword)
                {
                    Caption = 'Initial Password';
                    ToolTip = 'Initial password of the shop account (used when the account is created in the shop).';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OkAction)
            {
                Caption = 'OK';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    OkPressed := true;
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        LoginEmail: Text;
        NewPassword: Text;
        OkPressed: Boolean;

    procedure SetEmail(Email: Text)
    begin
        LoginEmail := Email;
    end;

    procedure GetPassword(): Text
    begin
        exit(NewPassword);
    end;

    procedure WasOkPressed(): Boolean
    begin
        exit(OkPressed);
    end;
}
