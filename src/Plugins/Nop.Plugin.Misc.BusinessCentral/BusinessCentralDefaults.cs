using Nop.Core;

namespace Nop.Plugin.Misc.BusinessCentral;

/// <summary>
/// Represents plugin constants
/// </summary>
public class BusinessCentralDefaults
{
    /// <summary>
    /// Gets the plugin system name
    /// </summary>
    public static string SystemName => "Misc.BusinessCentral";

    /// <summary>
    /// Gets the user agent used to request third-party services
    /// </summary>
    public static string UserAgent => $"nopCommerce-{NopVersion.CURRENT_VERSION}";

    /// <summary>
    /// Gets the configuration route name
    /// </summary>
    public static string ConfigurationRouteName => "Plugin.Misc.BusinessCentral.Configure";

    /// <summary>
    /// Gets a default period (in seconds) before the request times out
    /// </summary>
    public static int RequestTimeout => 30;

    /// <summary>
    /// Gets a name, type and period (in seconds) of the synchronization task.
    /// The task itself is registered during installation once the sync engine is implemented (phase P2).
    /// </summary>
    public static (string Name, string Type, int Period) SynchronizationTask =>
        ("Synchronization (Business Central plugin)", "Nop.Plugin.Misc.BusinessCentral.Services.BusinessCentralSyncTask", 900);

    /// <summary>
    /// Gets the OAuth 2.0 token endpoint for Microsoft Entra ID (client credentials flow)
    /// </summary>
    public static string TokenEndpoint => "https://login.microsoftonline.com/{0}/oauth2/v2.0/token";

    /// <summary>
    /// Gets the default scope for Business Central APIs
    /// </summary>
    public static string ApiScope => "https://api.businesscentral.dynamics.com/.default";

    /// <summary>
    /// Gets the Business Central API v2.0 base URL
    /// </summary>
    public static string ApiBaseUrl => "https://api.businesscentral.dynamics.com/v2.0/{0}/{1}/api/v2.0";
}
