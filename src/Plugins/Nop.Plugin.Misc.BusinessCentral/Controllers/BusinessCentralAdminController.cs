using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Nop.Core;
using Nop.Plugin.Misc.BusinessCentral.Models;
using Nop.Plugin.Misc.BusinessCentral.Services;
using Nop.Services.Common;
using Nop.Services.Configuration;
using Nop.Services.Localization;
using Nop.Services.Messages;
using Nop.Services.Security;
using Nop.Web.Framework;
using Nop.Web.Framework.Controllers;
using Nop.Web.Framework.Mvc.Filters;

namespace Nop.Plugin.Misc.BusinessCentral.Controllers;

[Area(AreaNames.ADMIN)]
[AuthorizeAdmin]
[AutoValidateAntiforgeryToken]
public class BusinessCentralAdminController : BasePluginController
{
    #region Fields

    protected readonly ILogger<BusinessCentralAdminController> _logger;
    protected readonly BusinessCentralService _businessCentralService;
    protected readonly IEncryptionService _encryptionService;
    protected readonly ILocalizationService _localizationService;
    protected readonly INotificationService _notificationService;
    protected readonly ISettingService _settingService;

    #endregion

    #region Ctor

    public BusinessCentralAdminController(ILogger<BusinessCentralAdminController> logger,
        BusinessCentralService businessCentralService,
        IEncryptionService encryptionService,
        ILocalizationService localizationService,
        INotificationService notificationService,
        ISettingService settingService)
    {
        _logger = logger;
        _businessCentralService = businessCentralService;
        _encryptionService = encryptionService;
        _localizationService = localizationService;
        _notificationService = notificationService;
        _settingService = settingService;
    }

    #endregion

    #region Utilities

    protected virtual async Task<ConfigurationModel> PrepareModelAsync()
    {
        var settings = await _settingService.LoadSettingAsync<BusinessCentralSettings>();

        var model = new ConfigurationModel
        {
            Enabled = settings.Enabled,
            UseSandbox = settings.UseSandbox,
            TenantId = settings.TenantId,
            EnvironmentName = settings.EnvironmentName,
            ClientId = settings.ClientId,
            ClientSecretSet = !string.IsNullOrEmpty(settings.ClientSecret),
            ApiKeySet = !string.IsNullOrEmpty(settings.ApiKey),
            CompanyName = settings.CompanyName,
            LogSyncMessages = settings.LogSyncMessages,
            RequestTimeout = settings.RequestTimeout
        };

        return model;
    }

    protected virtual async Task SaveSettingsAsync(ConfigurationModel model)
    {
        var settings = await _settingService.LoadSettingAsync<BusinessCentralSettings>();

        settings.Enabled = model.Enabled;
        settings.UseSandbox = model.UseSandbox;
        settings.TenantId = model.TenantId;
        settings.EnvironmentName = model.EnvironmentName;
        settings.ClientId = model.ClientId;

        //the client secret is stored encrypted; an empty value means "keep the current secret"
        if (!string.IsNullOrEmpty(model.ClientSecret))
            settings.ClientSecret = _encryptionService.EncryptText(model.ClientSecret);

        //the API key is stored encrypted as well; an empty value means "keep the current key"
        if (!string.IsNullOrEmpty(model.ApiKey))
            settings.ApiKey = _encryptionService.EncryptText(model.ApiKey);

        settings.CompanyName = model.CompanyName;
        settings.LogSyncMessages = model.LogSyncMessages;
        settings.RequestTimeout = model.RequestTimeout;

        await _settingService.SaveSettingAsync(settings);
    }

    #endregion

    #region Methods

    /// <summary>
    /// Display the configuration page
    /// </summary>
    [CheckPermission(StandardPermission.Configuration.MANAGE_PLUGINS)]
    public virtual async Task<IActionResult> Configure()
    {
        var model = await PrepareModelAsync();

        return View("~/Plugins/Misc.BusinessCentral/Views/Configure.cshtml", model);
    }

    /// <summary>
    /// Save the configuration
    /// </summary>
    [HttpPost]
    [CheckPermission(StandardPermission.Configuration.MANAGE_PLUGINS)]
    public virtual async Task<IActionResult> Configure(ConfigurationModel model)
    {
        if (!ModelState.IsValid)
            return await Configure();

        await SaveSettingsAsync(model);

        _notificationService.SuccessNotification(await _localizationService.GetResourceAsync("Admin.Plugins.Saved"));

        return await Configure();
    }

    /// <summary>
    /// Save the configuration and test the connection to Business Central
    /// </summary>
    [HttpPost]
    [CheckPermission(StandardPermission.Configuration.MANAGE_PLUGINS)]
    public virtual async Task<IActionResult> TestConnection(ConfigurationModel model)
    {
        if (!ModelState.IsValid)
            return await Configure();

        //persist the entered values first so that the connection is tested against exactly these values
        await SaveSettingsAsync(model);

        try
        {
            var settings = await _settingService.LoadSettingAsync<BusinessCentralSettings>();
            var companies = await _businessCentralService.TestConnectionAsync(settings);

            var companyNames = companies
                .Select(company => string.IsNullOrWhiteSpace(company.DisplayName) ? company.Name : company.DisplayName)
                .Where(name => !string.IsNullOrWhiteSpace(name))
                .ToList();

            if (companyNames.Count == 0)
                _notificationService.WarningNotification(
                    "The connection to Business Central was established successfully, but no companies were found in the configured environment.");
            else
                _notificationService.SuccessNotification(
                    $"The connection to Business Central was established successfully. Available companies: {string.Join(", ", companyNames)}.");
        }
        catch (Exception ex)
        {
            //do not expose sensitive details of unexpected errors, log them instead
            if (ex is not NopException)
                _logger.LogError(ex, "Failed to test the connection to Business Central");

            _notificationService.ErrorNotification(ex is NopException
                ? ex.Message
                : "Failed to test the connection to Business Central. See the log for details.");
        }

        return await Configure();
    }

    #endregion
}
