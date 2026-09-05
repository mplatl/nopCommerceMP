using Newtonsoft.Json;

namespace Nop.Plugin.Misc.BusinessCentral.Models.Api;

/// <summary>
/// Represents a product push request sent by the Business Central extension (catalog export).
/// The SKU is the mapping key between the Business Central item and the nopCommerce product.
/// </summary>
public class ProductPushRequest
{
    /// <summary>
    /// Gets or sets the SKU of the product (maps to the Business Central item number)
    /// </summary>
    public string Sku { get; set; }

    /// <summary>
    /// Gets or sets the product name
    /// </summary>
    public string Name { get; set; }

    /// <summary>
    /// Gets or sets the short description
    /// </summary>
    public string ShortDescription { get; set; }

    /// <summary>
    /// Gets or sets the full description
    /// </summary>
    public string FullDescription { get; set; }

    /// <summary>
    /// Gets or sets the (base) price
    /// </summary>
    public decimal? Price { get; set; }

    /// <summary>
    /// Gets or sets the current stock quantity
    /// </summary>
    public int? StockQuantity { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether the product is published (visible in the store)
    /// </summary>
    public bool? Published { get; set; }

    /// <summary>
    /// Gets or sets the currency code of the price (optional, informational)
    /// </summary>
    public string CurrencyCode { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether the product should be removed (archived)
    /// </summary>
    public bool? Remove { get; set; }
}
