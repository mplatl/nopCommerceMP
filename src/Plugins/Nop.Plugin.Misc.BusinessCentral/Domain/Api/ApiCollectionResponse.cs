using Newtonsoft.Json;

namespace Nop.Plugin.Misc.BusinessCentral.Domain.Api;

/// <summary>
/// Represents an OData collection response of the Business Central API
/// </summary>
/// <typeparam name="T">Type of the collection items</typeparam>
public class ApiCollectionResponse<T>
{
    /// <summary>
    /// Gets or sets the collection items
    /// </summary>
    [JsonProperty(PropertyName = "value")]
    public IList<T> Value { get; set; } = new List<T>();
}
