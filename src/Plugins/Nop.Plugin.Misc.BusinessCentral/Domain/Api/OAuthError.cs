using Newtonsoft.Json;

namespace Nop.Plugin.Misc.BusinessCentral.Domain.Api;

/// <summary>
/// Represents an error returned by the Microsoft Entra ID token endpoint
/// </summary>
public class OAuthError
{
    /// <summary>
    /// Gets or sets the error code
    /// </summary>
    [JsonProperty(PropertyName = "error")]
    public string Error { get; set; }

    /// <summary>
    /// Gets or sets the error description
    /// </summary>
    [JsonProperty(PropertyName = "error_description")]
    public string ErrorDescription { get; set; }
}
