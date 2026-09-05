using Newtonsoft.Json;

namespace Nop.Plugin.Misc.BusinessCentral.Domain.Api;

/// <summary>
/// Represents a Business Central company
/// </summary>
public class Company
{
    /// <summary>
    /// Gets or sets the unique identifier of the company
    /// </summary>
    [JsonProperty(PropertyName = "id")]
    public string Id { get; set; }

    /// <summary>
    /// Gets or sets the name of the company
    /// </summary>
    [JsonProperty(PropertyName = "name")]
    public string Name { get; set; }

    /// <summary>
    /// Gets or sets the display name of the company
    /// </summary>
    [JsonProperty(PropertyName = "displayName")]
    public string DisplayName { get; set; }

    /// <summary>
    /// Gets or sets the business profile identifier of the company
    /// </summary>
    [JsonProperty(PropertyName = "businessProfileId")]
    public string BusinessProfileId { get; set; }
}
