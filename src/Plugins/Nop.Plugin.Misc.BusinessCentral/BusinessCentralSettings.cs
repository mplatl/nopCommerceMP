using Nop.Core.Configuration;

namespace Nop.Plugin.Misc.BusinessCentral;

/// <summary>
/// Represents Business Central plugin settings
/// </summary>
public class BusinessCentralSettings : ISettings
{
    /// <summary>
    /// Gets or sets a value indicating whether the plugin is enabled
    /// </summary>
    public bool Enabled { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether the sandbox environment is used
    /// </summary>
    public bool UseSandbox { get; set; }

    /// <summary>
    /// Gets or sets the Microsoft Entra ID tenant id (GUID) that hosts the Business Central environment
    /// </summary>
    public string TenantId { get; set; }

    /// <summary>
    /// Gets or sets the name of the Business Central environment
    /// </summary>
    public string EnvironmentName { get; set; }

    /// <summary>
    /// Gets or sets the application (client) id of the app registered in Microsoft Entra ID
    /// </summary>
    public string ClientId { get; set; }

    /// <summary>
    /// Gets or sets the encrypted client secret of the registered app
    /// </summary>
    public string ClientSecret { get; set; }

    /// <summary>
    /// Gets or sets the name of the Business Central company used for synchronization
    /// </summary>
    public string CompanyName { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether sync messages should be logged
    /// </summary>
    public bool LogSyncMessages { get; set; }

    /// <summary>
    /// Gets or sets a default period (in seconds) before the request times out
    /// </summary>
    public int RequestTimeout { get; set; }
}
