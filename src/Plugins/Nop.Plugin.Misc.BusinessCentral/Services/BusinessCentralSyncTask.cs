using Microsoft.Extensions.Logging;
using Nop.Services.Configuration;
using Nop.Services.ScheduleTasks;

namespace Nop.Plugin.Misc.BusinessCentral.Services;

/// <summary>
/// Represents the schedule task that transfers the Business Central catalog to nopCommerce
/// (registered during plugin installation, adjustable in System → Schedule tasks)
/// </summary>
public class BusinessCentralSyncTask : IScheduleTask
{
    #region Fields

    protected readonly BusinessCentralService _businessCentralService;
    protected readonly ILogger<BusinessCentralSyncTask> _logger;
    protected readonly ISettingService _settingService;

    #endregion

    #region Ctor

    public BusinessCentralSyncTask(BusinessCentralService businessCentralService,
        ILogger<BusinessCentralSyncTask> logger,
        ISettingService settingService)
    {
        _businessCentralService = businessCentralService;
        _logger = logger;
        _settingService = settingService;
    }

    #endregion

    #region Methods

    /// <summary>
    /// Execute task: pulls the configured Business Central company items and creates/updates
    /// the nopCommerce products (mapping key: item number ↔ SKU)
    /// </summary>
    public async Task ExecuteAsync()
    {
        var settings = await _settingService.LoadSettingAsync<BusinessCentralSettings>();

        //do nothing while the plugin/connection is not enabled and configured
        if (!settings.Enabled)
        {
            _logger.LogDebug("Business Central synchronization skipped: the plugin is disabled.");
            return;
        }

        if (!_businessCentralService.IsConfigured(settings))
        {
            _logger.LogWarning("Business Central synchronization skipped: the connection is not configured (tenant, environment, client ID/secret, company).");
            return;
        }

        var result = await _businessCentralService.SyncCatalogAsync(settings);

        _logger.LogInformation("Business Central catalog synchronization finished: {Created} created, {Updated} updated, {Skipped} unchanged, {Errors} errors.",
            result.Created, result.Updated, result.Skipped, result.Errors.Count);
    }

    #endregion
}
