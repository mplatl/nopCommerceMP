using Microsoft.Net.Http.Headers;
using Newtonsoft.Json;
using Nop.Core;
using Nop.Plugin.Misc.BusinessCentral.Domain.Api;

namespace Nop.Plugin.Misc.BusinessCentral.Services;

/// <summary>
/// Represents the HTTP client used to request the Business Central API
/// (OAuth 2.0 client credentials flow + OData v4 endpoints)
/// </summary>
public class BusinessCentralHttpClient
{
    #region Fields

    protected readonly HttpClient _httpClient;

    //access tokens are cached per tenant and application (they are issued for one hour)
    protected readonly Dictionary<string, (string AccessToken, DateTime ExpiresAtUtc)> _accessTokenCache = new();

    #endregion

    #region Ctor

    public BusinessCentralHttpClient(HttpClient httpClient)
    {
        _httpClient = httpClient;

        _httpClient.DefaultRequestHeaders.Add(HeaderNames.UserAgent, BusinessCentralDefaults.UserAgent);
        _httpClient.DefaultRequestHeaders.Add(HeaderNames.Accept, MimeTypes.ApplicationJson);
    }

    #endregion

    #region Utilities

    /// <summary>
    /// Sends the request respecting the configured timeout
    /// </summary>
    protected async Task<HttpResponseMessage> SendRequestAsync(HttpRequestMessage request, BusinessCentralSettings settings,
        CancellationToken cancellationToken = default)
    {
        var timeout = settings.RequestTimeout > 0
            ? TimeSpan.FromSeconds(settings.RequestTimeout)
            : TimeSpan.FromSeconds(BusinessCentralDefaults.RequestTimeout);

        using var timeoutCancellationTokenSource = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCancellationTokenSource.CancelAfter(timeout);

        try
        {
            return await _httpClient.SendAsync(request, timeoutCancellationTokenSource.Token);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            throw new NopException($"The request to Business Central timed out after {(int)timeout.TotalSeconds} seconds.");
        }
    }

    /// <summary>
    /// Extracts a user-friendly message from an error returned by the Microsoft Entra ID token endpoint
    /// </summary>
    protected static string GetOAuthErrorMessage(string responseBody)
    {
        try
        {
            var error = JsonConvert.DeserializeObject<OAuthError>(responseBody);
            if (!string.IsNullOrEmpty(error?.ErrorDescription))
                return error.ErrorDescription;
        }
        catch
        {
            //response is not a JSON error, fall back to the raw body
        }

        return responseBody;
    }

    /// <summary>
    /// Extracts a user-friendly message from an error returned by the Business Central API
    /// </summary>
    protected static string GetApiErrorMessage(string responseBody)
    {
        try
        {
            var error = JsonConvert.DeserializeObject<ODataError>(responseBody);
            if (!string.IsNullOrEmpty(error?.Error?.Message))
                return error.Error.Message;
        }
        catch
        {
            //response is not a JSON error, fall back to the raw body
        }

        return responseBody;
    }

    #endregion

    #region Methods

    /// <summary>
    /// Obtains an access token for the given tenant and application using the OAuth 2.0 client credentials flow
    /// (a cached, still valid token is returned without a new request)
    /// </summary>
    public async Task<string> GetAccessTokenAsync(BusinessCentralSettings settings, string clientSecret)
    {
        var cacheKey = $"{settings.TenantId}|{settings.ClientId}";
        if (_accessTokenCache.TryGetValue(cacheKey, out var cachedToken) && cachedToken.ExpiresAtUtc > DateTime.UtcNow)
            return cachedToken.AccessToken;

        var tokenEndpoint = string.Format(BusinessCentralDefaults.TokenEndpoint, settings.TenantId);

        var request = new HttpRequestMessage(HttpMethod.Post, tokenEndpoint)
        {
            Content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["grant_type"] = "client_credentials",
                ["client_id"] = settings.ClientId,
                ["client_secret"] = clientSecret,
                ["scope"] = BusinessCentralDefaults.ApiScope
            })
        };

        var response = await SendRequestAsync(request, settings);
        var responseBody = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new NopException(
                $"Authentication with Microsoft Entra ID failed (HTTP {(int)response.StatusCode} {response.ReasonPhrase}): {GetOAuthErrorMessage(responseBody)}");

        var token = JsonConvert.DeserializeObject<OAuthToken>(responseBody)
            ?? throw new NopException("Authentication with Microsoft Entra ID failed: the token response is empty.");

        //cache the token until shortly before it expires to avoid unnecessary requests
        _accessTokenCache[cacheKey] = (token.AccessToken, DateTime.UtcNow.AddSeconds(Math.Max(token.ExpiresIn - 60, 0)));

        return token.AccessToken;
    }

    /// <summary>
    /// Performs a GET request against the given relative API path and deserializes the JSON response
    /// </summary>
    /// <typeparam name="TResponse">Type of the expected response</typeparam>
    /// <param name="settings">Plugin settings (tenant, environment, timeout)</param>
    /// <param name="accessToken">Valid access token</param>
    /// <param name="path">Relative API path, e.g. "companies" or "companies({id})/items"</param>
    public async Task<TResponse> GetAsync<TResponse>(BusinessCentralSettings settings, string accessToken, string path)
    {
        var baseUrl = string.Format(BusinessCentralDefaults.ApiBaseUrl, settings.TenantId, settings.EnvironmentName);
        var request = new HttpRequestMessage(HttpMethod.Get, $"{baseUrl}/{path.TrimStart('/')}");
        request.Headers.Add(HeaderNames.Authorization, $"Bearer {accessToken}");

        var response = await SendRequestAsync(request, settings);
        var responseBody = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
            throw new NopException(
                $"Business Central API request to '{path}' failed (HTTP {(int)response.StatusCode} {response.ReasonPhrase}): {GetApiErrorMessage(responseBody)}");

        return JsonConvert.DeserializeObject<TResponse>(responseBody);
    }

    #endregion
}
