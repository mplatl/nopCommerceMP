namespace NopCommerceConnector;

/// <summary>
/// Enumeration of the export states of a product record within a nopCommerce shop.
/// Mirrors the Shopify product status (draft/active/archived) of the Microsoft Shopify Connector.
/// </summary>
enum 62100 "Nop Product Status"
{
    Extensible = false;

    value(0; Draft)
    {
        Caption = 'Draft';
        //product is not exported yet; keep it out of nopCommerce until explicitly activated
    }
    value(1; Active)
    {
        Caption = 'Active';
        //product is exported to nopCommerce and kept in sync
    }
    value(2; Archived)
    {
        Caption = 'Archived';
        //product was exported before and has been removed from nopCommerce (no further updates)
    }
}
