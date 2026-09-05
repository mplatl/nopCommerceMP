using Microsoft.Extensions.Logging;
using Nop.Core;
using Nop.Core.Domain.Catalog;
using Nop.Core.Domain.Media;
using Nop.Plugin.Misc.BusinessCentral.Domain.Api;
using Nop.Services.Catalog;
using Nop.Services.Common;
using Nop.Services.Media;
using Nop.Services.Security;

namespace Nop.Plugin.Misc.BusinessCentral.Services;

/// <summary>
/// Represents the Business Central service (nopCommerce actively pulls/pushes data via the BC API v2.0)
/// </summary>
public class BusinessCentralService
{
    #region Fields

    protected readonly IEncryptionService _encryptionService;
    protected readonly BusinessCentralHttpClient _httpClient;
    protected readonly ILogger<BusinessCentralService> _logger;
    protected readonly IPictureService _pictureService;
    protected readonly IProductService _productService;
    protected readonly IProductTemplateService _productTemplateService;

    #endregion

    #region Ctor

    public BusinessCentralService(BusinessCentralHttpClient httpClient,
        IEncryptionService encryptionService,
        ILogger<BusinessCentralService> logger,
        IPictureService pictureService,
        IProductService productService,
        IProductTemplateService productTemplateService)
    {
        _httpClient = httpClient;
        _encryptionService = encryptionService;
        _logger = logger;
        _pictureService = pictureService;
        _productService = productService;
        _productTemplateService = productTemplateService;
    }

    #endregion

    #region Utilities

    /// <summary>
    /// Decrypts the stored client secret of the registered Entra ID app
    /// </summary>
    protected virtual string DecryptClientSecret(BusinessCentralSettings settings)
    {
        if (string.IsNullOrEmpty(settings.ClientSecret))
            return string.Empty;

        try
        {
            return _encryptionService.DecryptText(settings.ClientSecret);
        }
        catch
        {
            return string.Empty;
        }
    }

    /// <summary>
    /// Gets an OAuth 2.0 access token (client credentials flow) for the Business Central API
    /// </summary>
    protected virtual async Task<string> GetAccessTokenAsync(BusinessCentralSettings settings)
    {
        var clientSecret = DecryptClientSecret(settings);

        if (string.IsNullOrEmpty(settings.TenantId) ||
            string.IsNullOrEmpty(settings.EnvironmentName) ||
            string.IsNullOrEmpty(settings.ClientId) ||
            string.IsNullOrEmpty(clientSecret))
            throw new NopException("The Business Central connection is not configured. Please complete the plugin configuration first.");

        var token = await _httpClient.GetAccessTokenAsync(settings, clientSecret);

        return string.IsNullOrEmpty(token)
            ? throw new NopException("Authentication against Microsoft Entra ID failed. Please check the client ID and client secret.")
            : token;
    }

    /// <summary>
    /// Resolves the configured company of the Business Central environment
    /// </summary>
    protected virtual async Task<Company> ResolveCompanyAsync(BusinessCentralSettings settings, string accessToken)
    {
        var companies = await _httpClient.GetAsync<ApiCollectionResponse<Company>>(settings, accessToken, BusinessCentralDefaults.CompaniesPath);

        if (companies?.Value == null || companies.Value.Count == 0)
            throw new NopException("No company was returned by Business Central. Please check the environment name and the API permissions.");

        if (string.IsNullOrWhiteSpace(settings.CompanyName))
            throw new NopException("The company name is not configured. Please select one of the available companies in the plugin configuration.");

        var companyName = settings.CompanyName.Trim();

        var company = companies.Value.FirstOrDefault(c => c != null &&
            (string.Equals(c.DisplayName?.Trim(), companyName, StringComparison.OrdinalIgnoreCase) ||
             string.Equals(c.Name?.Trim(), companyName, StringComparison.OrdinalIgnoreCase)));

        if (company == null)
            throw new NopException($"Company \"{settings.CompanyName}\" was not found in Business Central. Available companies: {string.Join(", ", companies.Value.Select(c => c.DisplayName ?? c.Name))}.");

        return company;
    }

    /// <summary>
    /// Creates/updates a product template reference (used for products that are created by the sync)
    /// </summary>
    protected virtual async Task<ProductTemplate> GetDefaultProductTemplateAsync()
    {
        var templates = await _productTemplateService.GetAllProductTemplatesAsync();

        return templates.FirstOrDefault();
    }

    #endregion

    #region Methods

    /// <summary>
    /// Gets a value indicating whether the connection can be used
    /// </summary>
    public virtual bool IsConfigured(BusinessCentralSettings settings)
    {
        return !string.IsNullOrEmpty(settings.TenantId) &&
               !string.IsNullOrEmpty(settings.EnvironmentName) &&
               !string.IsNullOrEmpty(settings.ClientId) &&
               !string.IsNullOrEmpty(settings.ClientSecret) &&
               !string.IsNullOrEmpty(settings.CompanyName);
    }

    /// <summary>
    /// Tests the connection to the Business Central API and returns the available companies
    /// </summary>
    public virtual async Task<IList<Company>> TestConnectionAsync(BusinessCentralSettings settings)
    {
        var accessToken = await GetAccessTokenAsync(settings);
        var companies = await _httpClient.GetAsync<ApiCollectionResponse<Company>>(settings, accessToken, BusinessCentralDefaults.CompaniesPath);

        return companies?.Value ?? new List<Company>();
    }

    /// <summary>
    /// Loads all items of the configured company from Business Central (paged; full pull per run)
    /// </summary>
    public virtual async Task<IList<Item>> GetItemsAsync(BusinessCentralSettings settings)
    {
        var accessToken = await GetAccessTokenAsync(settings);
        var company = await ResolveCompanyAsync(settings, accessToken);

        return await GetItemsAsync(settings, accessToken, company.Id);
    }

    /// <summary>
    /// Loads all items of the given company from Business Central (paged; full pull per run)
    /// </summary>
    protected virtual async Task<IList<Item>> GetItemsAsync(BusinessCentralSettings settings, string accessToken, string companyId)
    {
        var items = new List<Item>();
        var pageSize = BusinessCentralDefaults.ApiPageSize;
        var skip = 0;

        while (true)
        {
            var path = $"{string.Format(BusinessCentralDefaults.CompaniesItemsPath, companyId)}?$top={pageSize}&$skip={skip}";
            var page = await _httpClient.GetAsync<ApiCollectionResponse<Item>>(settings, accessToken, path);

            if (page?.Value == null || page.Value.Count == 0)
                break;

            items.AddRange(page.Value);

            if (page.Value.Count < pageSize)
                break;

            skip += page.Value.Count;
        }

        return items;
    }

    /// <summary>
    /// Downloads the first picture of the given item (if any) and attaches it to the nopCommerce product
    /// (the picture is only downloaded when the product does not have a picture yet)
    /// </summary>
    protected virtual async Task AttachItemPictureIfMissingAsync(BusinessCentralSettings settings, string accessToken,
        Company company, Item item, Product product, BusinessCentralSyncResult result)
    {
        if (item == null || product == null || string.IsNullOrEmpty(item.Id) || string.IsNullOrEmpty(product.Sku))
            return;

        //product already has at least one picture → nothing to do
        var existingPictures = await _productService.GetProductPicturesByProductIdAsync(product.Id);
        if (existingPictures.Count > 0)
            return;

        //read the pictures of the item (standard API: companies({id})/items({id})/picture)
        var path = string.Format(BusinessCentralDefaults.CompaniesItemsPicturePath, company.Id, item.Id);
        var pictures = await _httpClient.GetAsync<ApiCollectionResponse<Domain.Api.Picture>>(settings, accessToken, path);
        var picture = pictures?.Value?.FirstOrDefault();
        var mediaReadLink = picture?.GetMediaReadLink();

        if (string.IsNullOrEmpty(mediaReadLink))
            return;

        var (bytes, contentType) = await _httpClient.GetBytesAsync(settings, accessToken, mediaReadLink);

        if (bytes == null || bytes.Length == 0)
            return;

        if (bytes.Length > 8 * 1024 * 1024)
        {
            result.Errors.Add($"{product.Sku}: picture exceeds the 8 MB limit ({bytes.Length} bytes) and was skipped.");
            return;
        }

        var savedPicture = await _pictureService.InsertPictureAsync(bytes, contentType ?? MimeTypes.ImageJpeg, null,
            null, null, true, false);
        await _productService.InsertProductPictureAsync(new ProductPicture
        {
            ProductId = product.Id,
            PictureId = savedPicture.Id,
            DisplayOrder = 1
        });

        result.PicturesAdded++;
        _logger.LogInformation("Business Central picture attached to product \"{Sku}\".", product.Sku);
    }

    /// <summary>
    /// Synchronizes the Business Central catalog to nopCommerce:
    /// each item is created/updated as a product (mapping key: item number ↔ SKU, idempotent)
    /// </summary>
    public virtual async Task<BusinessCentralSyncResult> SyncCatalogAsync(BusinessCentralSettings settings)
    {
        var result = new BusinessCentralSyncResult();

        if (!IsConfigured(settings))
            throw new NopException("The Business Central connection is not configured. Please complete the plugin configuration first.");

        var accessToken = await GetAccessTokenAsync(settings);
        var company = await ResolveCompanyAsync(settings, accessToken);
        var items = await GetItemsAsync(settings, accessToken, company.Id);

        if (items.Count == 0)
        {
            _logger.LogInformation("Business Central catalog synchronization: no items found for company \"{Company}\".", settings.CompanyName);
            return result;
        }

        var template = await GetDefaultProductTemplateAsync();

        foreach (var item in items)
        {
            if (string.IsNullOrWhiteSpace(item?.Number))
            {
                result.Skipped++;
                continue;
            }

            var sku = item.Number.Trim();

            try
            {
                var product = await _productService.GetProductBySkuAsync(sku);

                if (product == null)
                {
                    //create a new simple product (mirrors the inbound product push endpoint)
                    product = new Product
                    {
                        ProductTypeId = (int)ProductType.SimpleProduct,
                        VisibleIndividually = true,
                        AllowCustomerReviews = true,
                        ProductTemplateId = template?.Id ?? 0,
                        Name = !string.IsNullOrWhiteSpace(item.DisplayName) ? item.DisplayName.Trim() : sku,
                        Sku = sku,
                        Published = !(item.Blocked ?? false)
                    };

                    if (!string.IsNullOrWhiteSpace(item.Gtin))
                        product.Gtin = item.Gtin.Trim();
                    if (item.UnitPrice.HasValue)
                        product.Price = item.UnitPrice.Value;
                    if (item.Inventory.HasValue)
                    {
                        product.StockQuantity = (int)item.Inventory.Value;
                        product.ManageInventoryMethodId = (int)ManageInventoryMethod.ManageStock;
                    }

                    await _productService.InsertProductAsync(product);
                    result.Created++;
                }
                else
                {
                    //update only the fields that really changed
                    var changed = false;

                    if (!string.IsNullOrWhiteSpace(item.DisplayName) && product.Name != item.DisplayName.Trim())
                    {
                        product.Name = item.DisplayName.Trim();
                        changed = true;
                    }

                    if (!string.IsNullOrWhiteSpace(item.Gtin) && product.Gtin != item.Gtin.Trim())
                    {
                        product.Gtin = item.Gtin.Trim();
                        changed = true;
                    }

                    if (item.Blocked.HasValue && product.Published == item.Blocked.Value)
                    {
                        product.Published = !item.Blocked.Value;
                        changed = true;
                    }

                    if (item.UnitPrice.HasValue && product.Price != item.UnitPrice.Value)
                    {
                        product.Price = item.UnitPrice.Value;
                        changed = true;
                    }

                    if (item.Inventory.HasValue && product.StockQuantity != (int)item.Inventory.Value)
                    {
                        product.StockQuantity = (int)item.Inventory.Value;
                        product.ManageInventoryMethodId = (int)ManageInventoryMethod.ManageStock;
                        changed = true;
                    }

                    if (changed)
                    {
                        await _productService.UpdateProductAsync(product);
                        result.Updated++;
                    }
                    else
                        result.Skipped++;
                }

                //attach the item picture (only when the product has none yet)
                await AttachItemPictureIfMissingAsync(settings, accessToken, company, item, product, result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Business Central catalog synchronization failed for SKU {Sku}", sku);
                result.Errors.Add($"{sku}: {ex.Message}");
            }
        }

        _logger.LogInformation("Business Central catalog synchronization finished for company \"{Company}\": {Created} created, {Updated} updated, {Skipped} unchanged, {Pictures} pictures added, {Errors} errors.",
            settings.CompanyName, result.Created, result.Updated, result.Skipped, result.PicturesAdded, result.Errors.Count);

        return result;
    }

    #endregion
}
