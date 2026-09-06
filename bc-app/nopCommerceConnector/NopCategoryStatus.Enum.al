namespace NopCommerceConnector;

/// <summary>
/// Enumeration of the states of a category record within a nopCommerce shop.
/// Mirrors the export states of the store product records ("Nop Product"):
/// Draft = category not created in nopCommerce yet, Active = category created/kept in sync.
/// </summary>
enum 62133 "Nop Category Status"
{
    Extensible = false;

    value(0; Draft)
    {
        Caption = 'Draft';
        //category is not created in nopCommerce yet
    }
    value(1; Active)
    {
        Caption = 'Active';
        //category is created in nopCommerce and kept in sync
    }
}
