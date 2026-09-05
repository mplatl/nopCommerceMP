namespace NopCommerceConnector;

/// <summary>
/// Central management codeunit for the nopCommerce integration (mirrors the Microsoft Shopify "Mgt." codeunits).
/// Orchestrates the connection, the product export and the import of orders/customers.
/// </summary>
codeunit 62100 "Nop Commerce Mgt."
{
    /// <summary>
    /// Verifies the configured nopCommerce connection of a shop.
    /// </summary>
    /// <param name="Shop">The shop to test.</param>
    internal procedure TestConnection(Shop: Record "Nop Commerce Shop")
    var
        NopSetupTestOkMsg: Label 'The shop "%1" (%2) is ready. nopCommerce endpoint checks will run once the plugin API is published.', Comment = 'Placeholder until the nopCommerce REST endpoints are implemented (Iteration B).';
    begin
        Shop.ValidateSetup();

        //TODO Iteration B: call the nopCommerce plugin health endpoint and surface the result
        Message(NopSetupTestOkMsg, Shop.Code, Shop."Nop Commerce URL");
    end;
}
