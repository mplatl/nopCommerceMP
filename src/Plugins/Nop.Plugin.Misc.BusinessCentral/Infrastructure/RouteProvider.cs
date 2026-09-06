using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Routing;
using Nop.Web.Framework;
using Nop.Web.Framework.Mvc.Routing;

namespace Nop.Plugin.Misc.BusinessCentral.Infrastructure;

/// <summary>
/// Represents plugin route provider
/// </summary>
public class RouteProvider : IRouteProvider
{
    /// <summary>
    /// Register routes
    /// </summary>
    /// <param name="endpointRouteBuilder">Route builder</param>
    public void RegisterRoutes(IEndpointRouteBuilder endpointRouteBuilder)
    {
        endpointRouteBuilder.MapControllerRoute(name: BusinessCentralDefaults.ConfigurationRouteName,
            pattern: "Admin/BusinessCentral/{action=Configure}/{id?}",
            defaults: new { controller = "BusinessCentralAdmin", area = AreaNames.ADMIN });

        //public API endpoints called by the Business Central extension (no admin area, API key auth)
        endpointRouteBuilder.MapControllerRoute(name: BusinessCentralDefaults.ApiHealthRouteName,
            pattern: BusinessCentralDefaults.ApiHealthRoute,
            defaults: new { controller = "BusinessCentralApi", action = "Health" });

        endpointRouteBuilder.MapControllerRoute(name: BusinessCentralDefaults.ApiProductsRouteName,
            pattern: BusinessCentralDefaults.ApiProductsRoute,
            defaults: new { controller = "BusinessCentralApi", action = "Products" });

        endpointRouteBuilder.MapControllerRoute(name: BusinessCentralDefaults.ApiOrdersRouteName,
            pattern: BusinessCentralDefaults.ApiOrdersRoute,
            defaults: new { controller = "BusinessCentralApi", action = "Orders" });

        endpointRouteBuilder.MapControllerRoute(name: BusinessCentralDefaults.ApiCustomersRouteName,
            pattern: BusinessCentralDefaults.ApiCustomersRoute,
            defaults: new { controller = "BusinessCentralApi", action = "Customers" });

        endpointRouteBuilder.MapControllerRoute(name: BusinessCentralDefaults.ApiLanguagesRouteName,
            pattern: BusinessCentralDefaults.ApiLanguagesRoute,
            defaults: new { controller = "BusinessCentralApi", action = "Languages" });
    }

    /// <summary>
    /// Gets a priority of route provider
    /// </summary>
    public int Priority => 0;
}
