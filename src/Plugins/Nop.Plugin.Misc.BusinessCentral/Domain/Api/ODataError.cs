using Newtonsoft.Json;

namespace Nop.Plugin.Misc.BusinessCentral.Domain.Api;

/// <summary>
/// Represents an error returned by the Business Central API (OData JSON error)
/// </summary>
public class ODataError
{
    /// <summary>
    /// Gets or sets the error details
    /// </summary>
    [JsonProperty(PropertyName = "error")]
    public ErrorDetails Error { get; set; }

    /// <summary>
    /// Represents the details of an OData error
    /// </summary>
    public class ErrorDetails
    {
        /// <summary>
        /// Gets or sets the error code
        /// </summary>
        [JsonProperty(PropertyName = "code")]
        public string Code { get; set; }

        /// <summary>
        /// Gets or sets the error message
        /// </summary>
        [JsonProperty(PropertyName = "message")]
        public string Message { get; set; }
    }
}
