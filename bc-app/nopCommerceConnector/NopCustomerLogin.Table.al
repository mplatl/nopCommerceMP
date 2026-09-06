namespace NopCommerceConnector;

/// <summary>
/// Represents a customer login (Debitor) that is used by a shop (linked to the shop).
/// Several logins per customer (Debitor) are possible: each row = one login in the
/// nopCommerce store, assigned to a shop like the store products ("Nop Product").
/// The login is identified by the customer's e-mail (unique per shop); the initial
/// password is transferred to nopCommerce when the row is pushed (like the product export).
/// Only logins with a record here are created/kept in the shop ("whitelist").
/// </summary>
table 62116 "Nop Customer Login"
{
    Caption = 'nopCommerce Customer Login';
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
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Debitor (customer) in Business Central to whom this shop login belongs.';
        }
        field(3; "E-mail"; Text[250])
        {
            Caption = 'E-mail';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Login (user name) of the customer in the nopCommerce store - the e-mail address of the account.';
        }
        field(4; "Initial Password"; Text[250])
        {
            Caption = 'Initial Password';
            DataClassification = CustomerContent;
            ToolTip = 'Initial password that is set for the login in the nopCommerce store (transferred when the row is pushed).';
        }
        field(5; Status; enum "Nop Customer Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            NotBlank = true;
            ToolTip = 'Draft = login not created yet, Active = login created/kept in sync in the nopCommerce store.';
        }
        field(6; "Nop Customer Id"; Integer)
        {
            Caption = 'nopCommerce Customer Id';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Identifier of the customer in the nopCommerce store (set by the transfer).';
        }
        field(7; "Synchronized Date"; DateTime)
        {
            Caption = 'Synchronized Date';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Date and time of the last successful transfer of this customer login.';
        }
        field(8; "Last Sync Error"; Text[250])
        {
            Caption = 'Last Sync Error';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Contains the error message of the last failed transfer, if any.';
        }
        field(9; Name; Text[250])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            ToolTip = 'Display name of the customer account in the nopCommerce store (used at the account creation, e.g. the customer/company name).';
        }
    }

    keys
    {
        //several logins per customer (Debitor) are possible: one row per login/e-mail.
        //The e-mail is the login in the nopCommerce store and stays unique per shop.
        key(PK; "Shop Code", "Customer No.", "E-mail")
        {
            Clustered = true;
        }
    }
}
