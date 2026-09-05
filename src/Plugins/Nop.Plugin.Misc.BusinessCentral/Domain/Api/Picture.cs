using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Nop.Plugin.Misc.BusinessCentral.Domain.Api;

/// <summary>
/// Represents a picture linked to a Business Central record (item, customer, vendor, …).
/// The binary content is delivered through the media read link exposed by the API
/// (property name varies per field, therefore captured via extension data).
/// </summary>
public class Picture
{
    /// <summary>
    /// Gets or sets the additional (media) properties returned by the API,
    /// e.g. "pictureContent@odata.mediaReadLink" or "contentType"
    /// </summary>
    [JsonExtensionData]
    public IDictionary<string, JToken> ExtensionData { get; set; } = new Dictionary<string, JToken>();

    /// <summary>
    /// Gets the URL to download the picture content (null if no media is present)
    /// </summary>
    public string GetMediaReadLink()
    {
        return ExtensionData
            .Where(e => e.Key.Contains("@odata.mediaReadLink", StringComparison.OrdinalIgnoreCase))
            .Select(e => e.Value?.ToString())
            .FirstOrDefault(v => !string.IsNullOrEmpty(v));
    }

    /// <summary>
    /// Gets the content type of the picture (e.g. "image/jpeg"), if returned
    /// </summary>
    public string GetContentType()
    {
        return ExtensionData
            .Where(e => e.Key.Equals("contentType", StringComparison.OrdinalIgnoreCase))
            .Select(e => e.Value?.ToString())
            .FirstOrDefault(v => !string.IsNullOrEmpty(v));
    }
}
