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

    /// <summary>
    /// Gets the relative path of the companies endpoint
    /// </summary>
    public static string CompaniesPath => "companies";

    /// <summary>
    /// Gets the name of the HTTP header that carries the API key of incoming requests from Business Central
    /// </summary>
    public static string ApiKeyHeaderName => "X-Api-Key";

    /// <summary>
    /// Gets the route pattern of the health endpoint (public API for Business Central)
    /// </summary>
    public static string ApiHealthRoute => "api/bc/health";

    /// <summary>
    /// Gets the route pattern of the product push endpoint (public API for Business Central)
    /// </summary>
    public static string ApiProductsRoute => "api/bc/products";

    /// <summary>
    /// Gets the route pattern of the order export endpoint (public API for Business Central)
    /// </summary>
    public static string ApiOrdersRoute => "api/bc/orders";

    /// <summary>
    /// Gets the route pattern of the customer export endpoint (public API for Business Central)
    /// </summary>
    public static string ApiCustomersRoute => "api/bc/customers";

    /// <summary>
    /// Gets the API route name used to register the health endpoint
    /// </summary>
    public static string ApiHealthRouteName => "Plugin.Misc.BusinessCentral.ApiHealth";

    /// <summary>
    /// Gets the API route name used to register the product push endpoint
    /// </summary>
    public static string ApiProductsRouteName => "Plugin.Misc.BusinessCentral.ApiProducts";

    /// <summary>
    /// Gets the API route name used to register the order export endpoint
    /// </summary>
    public static string ApiOrdersRouteName => "Plugin.Misc.BusinessCentral.ApiOrders";

    /// <summary>
    /// Gets the API route name used to register the customer export endpoint
    /// </summary>
    public static string ApiCustomersRouteName => "Plugin.Misc.BusinessCentral.ApiCustomers";
}
