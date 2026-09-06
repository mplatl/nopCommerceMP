namespace NopCommerceConnector;

/// <summary>
/// Enumeration of the states of a customer login (Debitor) record within a nopCommerce shop.
/// Mirrors the export states of the store product records ("Nop Product"):
/// Draft = login not created yet, Active = login created/kept in sync in nopCommerce.
/// </summary>
enum 62115 "Nop Customer Status"
{
    Extensible = false;

    value(0; Draft)
    {
        Caption = 'Draft';
        //customer login is not created in nopCommerce yet
    }
    value(1; Active)
    {
        Caption = 'Active';
        //customer login is created in nopCommerce and kept in sync
    }
}
