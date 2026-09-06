namespace Nop.Plugin.Misc.BusinessCentral.Models.Api;

/// <summary>
/// Request of the category registration endpoint (Business Central pushes the
/// per-shop categories into nopCommerce; parent categories are created first,
/// Business Central then sends the nopCommerce parent id)
/// </summary>
public class CategoryRegisterRequest
{
    /// <summary>
    /// Gets or sets the name of the category
    /// </summary>
    public string Name { get; set; }

    /// <summary>
    /// Gets or sets the description text of the category
    /// </summary>
    public string Description { get; set; }

    /// <summary>
    /// Gets or sets the nopCommerce id of the parent category (0 = top-level category)
    /// </summary>
    public int ParentId { get; set; }

    /// <summary>
    /// Gets or sets the Business Central category code of this shop.
    /// Stored as category attribute "bcCategoryCode" on the nopCommerce category for traceability.
    /// </summary>
    public string BcCategoryCode { get; set; }
}
