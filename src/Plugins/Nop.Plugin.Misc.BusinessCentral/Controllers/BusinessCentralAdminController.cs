using Microsoft.AspNetCore.Mvc;
using Nop.Plugin.Misc.BusinessCentral.Models;
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

    protected readonly IEncryptionService _encryptionService;
    protected readonly ILocalizationService _localizationService;
    protected readonly INotificationService _notificationService;
    protected readonly ISettingService _settingService;

    #endregion

    #region Ctor

    public BusinessCentralAdminController(IEncryptionService encryptionService,
        ILocalizationService localizationService,
        INotificationService notificationService,
        ISettingService settingService)
    {
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
            CompanyName = settings.CompanyName,
            LogSyncMessages = settings.LogSyncMessages,
            RequestTimeout = settings.RequestTimeout
        };

        return model;
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

        var settings = await _settingService.LoadSettingAsync<BusinessCentralSettings>();

        settings.Enabled = model.Enabled;
        settings.UseSandbox = model.UseSandbox;
        settings.TenantId = model.TenantId;
        settings.EnvironmentName = model.EnvironmentName;
        settings.ClientId = model.ClientId;

        //the client secret is stored encrypted; an empty value means "keep the current secret"
        if (!string.IsNullOrEmpty(model.ClientSecret))
            settings.ClientSecret = _encryptionService.EncryptText(model.ClientSecret);

        settings.CompanyName = model.CompanyName;
        settings.LogSyncMessages = model.LogSyncMessages;
        settings.RequestTimeout = model.RequestTimeout;

        await _settingService.SaveSettingAsync(settings);

        _notificationService.SuccessNotification(await _localizationService.GetResourceAsync("Admin.Plugins.Saved"));

        return await Configure();
    }

    #endregion
}
