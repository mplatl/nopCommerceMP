using Nop.Services.Common;
using Nop.Services.Configuration;
using Nop.Services.Localization;
using Nop.Services.Plugins;
using Nop.Web.Framework.Mvc.Routing;

namespace Nop.Plugin.Misc.BusinessCentral;

/// <summary>
/// Represents the Business Central plugin
/// </summary>
public class BusinessCentralPlugin : BasePlugin, IMiscPlugin
{
    #region Fields

    protected readonly ILocalizationService _localizationService;
    protected readonly INopUrlHelper _nopUrlHelper;
    protected readonly ISettingService _settingService;

    #endregion

    #region Ctor

    public BusinessCentralPlugin(ILocalizationService localizationService,
        INopUrlHelper nopUrlHelper,
        ISettingService settingService)
    {
        _localizationService = localizationService;
        _nopUrlHelper = nopUrlHelper;
        _settingService = settingService;
    }

    #endregion

    #region Methods

    /// <summary>
    /// Gets a configuration page URL
    /// </summary>
    public override string GetConfigurationPageUrl()
    {
        return _nopUrlHelper.RouteUrl(BusinessCentralDefaults.ConfigurationRouteName);
    }

    /// <summary>
    /// Install the plugin
    /// </summary>
    /// <returns>A task that represents the asynchronous operation</returns>
    public override async Task InstallAsync()
    {
        //ensure the plugin is disabled until the connection is configured and validated
        await _settingService.SaveSettingAsync(new BusinessCentralSettings
        {
            Enabled = false,
            UseSandbox = true,
            LogSyncMessages = true,
            RequestTimeout = BusinessCentralDefaults.RequestTimeout
        });

        //locales
        await _localizationService.AddOrUpdateLocaleResourceAsync(new Dictionary<string, string>
        {
            ["Plugins.Misc.BusinessCentral.Enabled"] = "Enabled",
            ["Plugins.Misc.BusinessCentral.Enabled.Hint"] = "Check to enable the connection to Business Central.",
            ["Plugins.Misc.BusinessCentral.UseSandbox"] = "Use sandbox environment",
            ["Plugins.Misc.BusinessCentral.UseSandbox.Hint"] = "Check to connect to the Business Central sandbox instead of the production environment.",
            ["Plugins.Misc.BusinessCentral.TenantId"] = "Tenant ID",
            ["Plugins.Misc.BusinessCentral.TenantId.Hint"] = "The Microsoft Entra ID tenant ID (GUID) that hosts your Business Central environment.",
            ["Plugins.Misc.BusinessCentral.EnvironmentName"] = "Environment name",
            ["Plugins.Misc.BusinessCentral.EnvironmentName.Hint"] = "The name of your Business Central environment (e.g. \"sandbox\" or \"production\").",
            ["Plugins.Misc.BusinessCentral.ClientId"] = "Client ID",
            ["Plugins.Misc.BusinessCentral.ClientId.Hint"] = "The application (client) ID of the app you registered in Microsoft Entra ID.",
            ["Plugins.Misc.BusinessCentral.ClientSecret"] = "Client secret",
            ["Plugins.Misc.BusinessCentral.ClientSecret.Hint"] = "The client secret of the registered app. It is stored encrypted. Leave empty to keep the current secret.",
            ["Plugins.Misc.BusinessCentral.ClientSecret.AlreadySet"] = "A client secret is already set. Enter a new value only to replace it.",
            ["Plugins.Misc.BusinessCentral.ApiKey"] = "API key (for Business Central)",
            ["Plugins.Misc.BusinessCentral.ApiKey.Hint"] = "The API key that authorizes requests from Business Central to this store's plugin endpoints (products, orders, customers). Enter the same key in the nopCommerce shop card of the Business Central extension. It is stored encrypted. Leave empty to keep the current key.",
            ["Plugins.Misc.BusinessCentral.ApiKey.AlreadySet"] = "An API key is already set. Enter a new value only to replace it.",
            ["Plugins.Misc.BusinessCentral.CompanyName"] = "Company name",
            ["Plugins.Misc.BusinessCentral.CompanyName.Hint"] = "The Business Central company that is synchronized with this store.",
            ["Plugins.Misc.BusinessCentral.LogSyncMessages"] = "Log sync messages",
            ["Plugins.Misc.BusinessCentral.LogSyncMessages.Hint"] = "Check to log synchronization activity and errors. Useful for troubleshooting.",
            ["Plugins.Misc.BusinessCentral.RequestTimeout"] = "Request timeout (seconds)",
            ["Plugins.Misc.BusinessCentral.RequestTimeout.Hint"] = "The default period (in seconds) before a request to Business Central times out.",
            ["Plugins.Misc.BusinessCentral.InstructionsTitle"] = "How to connect",
            ["Plugins.Misc.BusinessCentral.InstructionsText1"] = "1. Make sure you have a Business Central environment (sandbox or production) with API access enabled.",
            ["Plugins.Misc.BusinessCentral.InstructionsText2"] = "2. Register an app in Microsoft Entra ID (Azure portal) in the same tenant as Business Central and grant it the Dynamics 365 Business Central application permission (API.ReadWrite.All) with admin consent.",
            ["Plugins.Misc.BusinessCentral.InstructionsText3"] = "3. Enter the tenant ID, environment name, client ID and client secret below and save.",
            ["Plugins.Misc.BusinessCentral.InstructionsText4"] = "4. Click \"Test connection\" to verify that the connection works. On success, the companies available in your environment are listed — use one of these names as the company name.",
            ["Plugins.Misc.BusinessCentral.TestConnection"] = "Test connection"
        });

        await base.InstallAsync();
    }

    /// <summary>
    /// Uninstall the plugin
    /// </summary>
    /// <returns>A task that represents the asynchronous operation</returns>
    public override async Task UninstallAsync()
    {
        //delete settings
        await _settingService.DeleteSettingAsync<BusinessCentralSettings>();

        //delete locales
        await _localizationService.DeleteLocaleResourcesAsync("Plugins.Misc.BusinessCentral");

        await base.UninstallAsync();
    }

    #endregion
}
