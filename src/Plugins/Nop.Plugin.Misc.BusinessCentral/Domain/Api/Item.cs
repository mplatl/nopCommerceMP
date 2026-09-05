using Newtonsoft.Json;

namespace Nop.Plugin.Misc.BusinessCentral.Domain.Api;

/// <summary>
/// Represents an item (catalog article) of a Business Central company
/// </summary>
public class Item
{
    /// <summary>
    /// Gets or sets the unique identifier of the item
    /// </summary>
    [JsonProperty(PropertyName = "id")]
    public string Id { get; set; }

    /// <summary>
    /// Gets or sets the item number (used as the mapping key to the nopCommerce SKU)
    /// </summary>
    [JsonProperty(PropertyName = "number")]
    public string Number { get; set; }

    /// <summary>
    /// Gets or sets the display name of the item
    /// </summary>
    [JsonProperty(PropertyName = "displayName")]
    public string DisplayName { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether the item is blocked
    /// </summary>
    [JsonProperty(PropertyName = "blocked")]
    public bool? Blocked { get; set; }

    /// <summary>
    /// Gets or sets the global trade item number of the item
    /// </summary>
    [JsonProperty(PropertyName = "gtin")]
    public string Gtin { get; set; }

    /// <summary>
    /// Gets or sets the unit price of the item.
    /// NOTE: only filled if the environment exposes price fields on the item API
    /// (otherwise keep the nopCommerce price and maintain it via a dedicated sync later)
    /// </summary>
    [JsonProperty(PropertyName = "unitPrice")]
    public decimal? UnitPrice { get; set; }

    /// <summary>
    /// Gets or sets the available inventory quantity of the item.
    /// NOTE: only filled if the environment exposes inventory on the item API
    /// (otherwise the nopCommerce stock is not touched)
    /// </summary>
    [JsonProperty(PropertyName = "inventory")]
    public decimal? Inventory { get; set; }
}
