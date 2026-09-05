using Newtonsoft.Json;

namespace Nop.Plugin.Misc.BusinessCentral.Domain.Api;

/// <summary>
/// Represents an OAuth 2.0 access token response (client credentials flow)
/// </summary>
public class OAuthToken
{
    /// <summary>
    /// Gets or sets the access token
    /// </summary>
    [JsonProperty(PropertyName = "access_token")]
    public string AccessToken { get; set; }

    /// <summary>
    /// Gets or sets the token type
    /// </summary>
    [JsonProperty(PropertyName = "token_type")]
    public string TokenType { get; set; }

    /// <summary>
    /// Gets or sets the lifetime (in seconds) of the access token
    /// </summary>
    [JsonProperty(PropertyName = "expires_in")]
    public int ExpiresIn { get; set; }
}
