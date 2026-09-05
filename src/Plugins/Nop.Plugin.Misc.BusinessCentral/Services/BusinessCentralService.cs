using Nop.Core;
using Nop.Plugin.Misc.BusinessCentral.Domain.Api;
using Nop.Services.Common;
using Nop.Services.Security;

namespace Nop.Plugin.Misc.BusinessCentral.Services;

/// <summary>
/// Represents the Business Central manager
/// (connection handling now; catalog/order synchronization will be added in later phases)
/// </summary>
public class BusinessCentralService
{
    #region Fields

    protected readonly BusinessCentralHttpClient _httpClient;
    protected readonly IEncryptionService _encryptionService;

    #endregion

    #region Ctor

    public BusinessCentralService(BusinessCentralHttpClient httpClient,
        IEncryptionService encryptionService)
    {
        _httpClient = httpClient;
        _encryptionService = encryptionService;
    }

    #endregion

    #region Utilities

    /// <summary>
    /// Decrypts the stored client secret
    /// </summary>
    protected virtual string DecryptClientSecret(BusinessCentralSettings settings)
    {
        if (string.IsNullOrEmpty(settings.ClientSecret))
            return string.Empty;

        try
        {
            return _encryptionService.DecryptText(settings.ClientSecret);
        }
        catch (Exception ex)
        {
            throw new NopException("The stored client secret could not be decrypted. Please save the client secret again.", ex);
        }
    }

    /// <summary>
    /// Obtains a valid access token for the configured tenant and application
    /// </summary>
    protected virtual async Task<string> GetAccessTokenAsync(BusinessCentralSettings settings)
    {
        if (!IsConfigured(settings))
            throw new NopException(
                "Business Central is not configured yet. Please enter tenant ID, environment name, client ID and client secret first.");

        return await _httpClient.GetAccessTokenAsync(settings, DecryptClientSecret(settings));
    }

    #endregion

    #region Methods

    /// <summary>
    /// Gets a value indicating whether all connection settings are present
    /// </summary>
    public virtual bool IsConfigured(BusinessCentralSettings settings)
    {
        return !string.IsNullOrWhiteSpace(settings.TenantId)
            && !string.IsNullOrWhiteSpace(settings.EnvironmentName)
            && !string.IsNullOrWhiteSpace(settings.ClientId)
            && !string.IsNullOrEmpty(settings.ClientSecret)
            && !string.IsNullOrEmpty(DecryptClientSecret(settings));
    }

    /// <summary>
    /// Tests the connection to Business Central: authenticates and loads the list of available companies
    /// </summary>
    /// <returns>The companies found in the configured environment</returns>
    public virtual async Task<IList<Company>> TestConnectionAsync(BusinessCentralSettings settings)
    {
        var accessToken = await GetAccessTokenAsync(settings);

        var response = await _httpClient.GetAsync<ApiCollectionResponse<Company>>(settings, accessToken, BusinessCentralDefaults.CompaniesPath);

        return response?.Value ?? new List<Company>();
    }

    #endregion
}
