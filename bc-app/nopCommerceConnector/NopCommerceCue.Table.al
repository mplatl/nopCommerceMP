namespace NopCommerceConnector;

/// <summary>
/// Backing table for the cue tiles ("Stapel") of the nopCommerce role center.
/// Contains one aggregate row (primary key blank) whose flow fields are calculated
/// on open/refresh of the role center and are displayed as cue counts.
/// </summary>
table 62113 "Nop Commerce Cue"
{
    Caption = 'nopCommerce Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            NotBlank = true;
        }
        field(2; "Shop Count"; Integer)
        {
            Caption = 'Shop Count';
            CalcFormula = count("Nop Commerce Shop");
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of connected nopCommerce shops (stores).';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
