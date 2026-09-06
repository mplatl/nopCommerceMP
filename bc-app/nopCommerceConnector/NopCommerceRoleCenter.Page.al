namespace NopCommerceConnector;

/// <summary>
/// Role Center for the nopCommerce connector: manage the connected shops (stores)
/// and the products that are selected per shop for the transfer to nopCommerce.
/// </summary>
page 62140 "nopCommerce Admin"
{
    ApplicationArea = All;
    Caption = 'nopCommerce Connector';
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter)
        {
            part(ShopCues; "Nop Commerce Shop Cue")
            {
                ApplicationArea = All;
                Caption = 'Shops';
            }
            part(ShopList; "Nop Commerce Shops Part")
            {
                ApplicationArea = All;
                Caption = 'nopCommerce Shops';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(New)
            {
                Caption = 'New';
                action(AddShop)
                {
                    ApplicationArea = All;
                    Caption = 'Shop';
                    Image = New;
                    RunObject = Page "Nop Commerce Setup";
                    RunPageMode = Create;
                    ToolTip = 'Create a new nopCommerce shop (store) connection.';
                }
            }
        }
        area(Embedding)
        {
            action(Shops)
            {
                ApplicationArea = All;
                Caption = 'Shops';
                RunObject = Page "Nop Commerce Shops";
                ToolTip = 'Open the list of nopCommerce shops (stores).';
            }
            action(Languages)
            {
                ApplicationArea = All;
                Caption = 'Languages';
                RunObject = Page "Nop Commerce Languages";
                ToolTip = 'Open the list of nopCommerce languages that are maintained per shop.';
            }
        }
    }
}
