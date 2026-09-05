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
    /// Gets the name of the synchronization task (registered during plugin installation)
    /// </summary>
    public static string SynchronizationTaskName => "Synchronization (Business Central plugin)";

    /// <summary>
    /// Gets the type of the synchronization task (catalog transfer from Business Central to nopCommerce)
    /// </summary>
    public static string SynchronizationTask => "Nop.Plugin.Misc.BusinessCentral.Services.BusinessCentralSyncTask";

    /// <summary>
    /// Gets the default run period (in seconds) of the synchronization task (adjustable in System → Schedule tasks)
    /// </summary>
    public static int DefaultSynchronizationPeriodSeconds => 15 * 60;

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
    /// Gets the relative path template of the items of a company (usage: string.Format(…, companyId))
    /// </summary>
    public static string CompaniesItemsPath => "companies({0})/items";

    /// <summary>
    /// Gets the number of records requested per page from the Business Central API
    /// </summary>
    public static int ApiPageSize => 100;

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
