namespace Nop.Plugin.Misc.BusinessCentral.Models;

/// <summary>
/// Represents a configuration model
/// </summary>
public record ConfigurationModel
{
    public bool Enabled { get; set; }

    public bool UseSandbox { get; set; }

    public string TenantId { get; set; }

    public string EnvironmentName { get; set; }

    public string ClientId { get; set; }

    public string ClientSecret { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether a client secret is already stored
    /// </summary>
    public bool ClientSecretSet { get; set; }

    public string ApiKey { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether an API key is already stored
    /// </summary>
    public bool ApiKeySet { get; set; }

    public string CompanyName { get; set; }

    public bool LogSyncMessages { get; set; }

    public int RequestTimeout { get; set; }
}
