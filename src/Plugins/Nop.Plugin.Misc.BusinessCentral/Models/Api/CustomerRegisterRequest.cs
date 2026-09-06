namespace Nop.Plugin.Misc.BusinessCentral.Models.Api;

/// <summary>
/// Request of the customer login registration endpoint (Business Central creates the
/// shop logins of its customers in nopCommerce with an initial password)
/// </summary>
public class CustomerRegisterRequest
{
    /// <summary>
    /// Gets or sets the e-mail address of the new login (login name in nopCommerce)
    /// </summary>
    public string Email { get; set; }

    /// <summary>
    /// Gets or sets the initial password of the new login
    /// </summary>
    public string Password { get; set; }

    /// <summary>
    /// Gets or sets the display name of the customer account (e.g. the Business Central customer name)
    /// </summary>
    public string Name { get; set; }

    /// <summary>
    /// Gets or sets the Business Central customer number (Debitor) that owns this login.
    /// Stored as customer attribute "bcCustomerNo" on the nopCommerce account so that orders
    /// of every login of the same customer are mapped to the same Bill-to customer.
    /// </summary>
    public string CustomerNo { get; set; }
}
