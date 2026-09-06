using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using Nop.Core.Domain.Catalog;
using Nop.Core.Domain.Common;
using Nop.Plugin.Misc.BusinessCentral.Models.Api;
using Nop.Services.Catalog;
using Nop.Services.Common;
using Nop.Services.Configuration;
using Nop.Services.Customers;
using Nop.Services.Directory;
using Nop.Services.Localization;
using Nop.Services.Orders;
using Nop.Services.Security;

namespace Nop.Plugin.Misc.BusinessCentral.Controllers;

/// <summary>
/// Public API endpoints called by the Business Central extension (outbound push/pull).
/// All requests are authenticated with the API key (header X-Api-Key).
/// </summary>
public class BusinessCentralApiController : Controller
{
    #region Fields

    protected readonly ILogger<BusinessCentralApiController> _logger;
    protected readonly IAddressService _addressService;
    protected readonly ICountryService _countryService;
    protected readonly ICustomerService _customerService;
    protected readonly IEncryptionService _encryptionService;
    protected readonly ILanguageService _languageService;
    protected readonly IOrderService _orderService;
    protected readonly IProductService _productService;
    protected readonly IProductTemplateService _productTemplateService;
    protected readonly ISettingService _settingService;
    protected readonly IStateProvinceService _stateProvinceService;

    #endregion

    #region Ctor

    public BusinessCentralApiController(ILogger<BusinessCentralApiController> logger,
        IAddressService addressService,
        ICountryService countryService,
        ICustomerService customerService,
        IEncryptionService encryptionService,
        ILanguageService languageService,
        IOrderService orderService,
        IProductService productService,
        IProductTemplateService productTemplateService,
        ISettingService settingService,
        IStateProvinceService stateProvinceService)
    {
        _logger = logger;
        _addressService = addressService;
        _countryService = countryService;
        _customerService = customerService;
        _encryptionService = encryptionService;
        _languageService = languageService;
        _orderService = orderService;
        _productService = productService;
        _productTemplateService = productTemplateService;
        _settingService = settingService;
        _stateProvinceService = stateProvinceService;
    }

    #endregion

    #region Utilities

    /// <summary>
    /// Validates the API key sent in the X-Api-Key header against the configured (decrypted) key
    /// </summary>
    protected virtual async Task<bool> IsApiKeyValidAsync()
    {
        var requestKey = Request.Headers[BusinessCentralDefaults.ApiKeyHeaderName].ToString();
        if (string.IsNullOrEmpty(requestKey))
            return false;

        var settings = await _settingService.LoadSettingAsync<BusinessCentralSettings>();
        if (string.IsNullOrEmpty(settings.ApiKey))
            return false;

        string configuredKey;
        try
        {
            configuredKey = _encryptionService.DecryptText(settings.ApiKey);
        }
        catch
        {
            return false;
        }

        return string.Equals(requestKey, configuredKey, StringComparison.Ordinal);
    }

    /// <summary>
    /// Writes a JSON result with the given status code (camelCase property names for the Business Central client)
    /// </summary>
    protected virtual IActionResult JsonResult(int statusCode, object data)
    {
        Response.StatusCode = statusCode;

        var settings = new JsonSerializerSettings
        {
            ContractResolver = new CamelCasePropertyNamesContractResolver()
        };

        return Content(JsonConvert.SerializeObject(data, settings), "application/json", Encoding.UTF8);
    }

    /// <summary>
    /// Parses the optional "since" query parameter (ISO 8601)
    /// </summary>
    protected virtual DateTime? ParseSince()
    {
        var raw = Request.Query["since"].ToString();
        if (string.IsNullOrEmpty(raw))
            return null;

        return DateTime.TryParse(raw, null, System.Globalization.DateTimeStyles.RoundtripKind, out _)
            ? DateTime.Parse(raw, null, System.Globalization.DateTimeStyles.RoundtripKind).ToUniversalTime()
            : null;
    }

    /// <summary>
    /// Reads the optional "max" query parameter (default 100, max 500)
    /// </summary>
    protected virtual int ParseMax()
    {
        var raw = Request.Query["max"].ToString();
        return int.TryParse(raw, out var max) && max > 0 ? Math.Min(max, 500) : 100;
    }

    /// <summary>
    /// Builds an address snapshot (country/state names resolved)
    /// </summary>
    protected virtual async Task<OrderAddressDto> BuildAddressAsync(Address address)
    {
        if (address == null)
            return null;

        var countryName = string.Empty;
        var stateName = string.Empty;

        if (address.CountryId.HasValue)
        {
            var country = await _countryService.GetCountryByIdAsync(address.CountryId.Value);
            countryName = country?.Name;
        }
        if (address.StateProvinceId.HasValue)
        {
            var state = await _stateProvinceService.GetStateProvinceByIdAsync(address.StateProvinceId.Value);
            stateName = state?.Name;
        }

        return new OrderAddressDto
        {
            FirstName = address.FirstName,
            LastName = address.LastName,
            Company = address.Company,
            Address1 = address.Address1,
            Address2 = address.Address2,
            City = address.City,
            ZipPostalCode = address.ZipPostalCode,
            Country = countryName,
            State = stateName,
            Phone = address.PhoneNumber,
            Email = address.Email
        };
    }

    #endregion

    #region Methods

    /// <summary>
    /// Health check used by the Business Central "Test Connection" (BC app calls this endpoint)
    /// </summary>
    public virtual async Task<IActionResult> Health()
    {
        if (!await IsApiKeyValidAsync())
            return JsonResult(StatusCodes.Status401Unauthorized, new { error = "Invalid API key" });

        return JsonResult(StatusCodes.Status200OK, new
        {
            status = "ok",
            plugin = BusinessCentralDefaults.SystemName,
            utcTime = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Creates or updates a product from the Business Central catalog export (push).
    /// The SKU is the mapping key to the Business Central item number.
    /// </summary>
    public virtual async Task<IActionResult> Products()
    {
        if (!await IsApiKeyValidAsync())
            return JsonResult(StatusCodes.Status401Unauthorized, new { error = "Invalid API key" });

        ProductPushRequest request;
        try
        {
            using var reader = new StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();
            request = JsonConvert.DeserializeObject<ProductPushRequest>(body);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Business Central product push: invalid request body");

            return JsonResult(StatusCodes.Status400BadRequest, new { error = "Invalid request body" });
        }

        if (request == null || string.IsNullOrWhiteSpace(request.Sku))
            return JsonResult(StatusCodes.Status400BadRequest, new { error = "The SKU is required" });

        try
        {
            var product = await _productService.GetProductBySkuAsync(request.Sku);

            //"remove" requests archive the product (nopCommerce keeps the record, like the BC "removed product" flow)
            if (request.Remove == true)
            {
                if (product == null)
                    return JsonResult(StatusCodes.Status200OK, new { sku = request.Sku, removed = true });

                //keep the record but stop publishing it (mirrors the BC "removed product" handling)
                product.Published = false;

                await _productService.UpdateProductAsync(product);

                return JsonResult(StatusCodes.Status200OK, new { sku = request.Sku, removed = true, productId = product.Id });
            }

            var isNew = product == null;
            if (isNew)
            {
                product = new Product
                {
                    ProductTypeId = (int)ProductType.SimpleProduct,
                    VisibleIndividually = true,
                    AllowCustomerReviews = true,
                    Name = request.Name ?? request.Sku
                };

                //a product template is required to render the product in the store
                var templates = await _productTemplateService.GetAllProductTemplatesAsync();
                product.ProductTemplateId = templates.Count > 0 ? templates[0].Id : 0;
            }

            if (!string.IsNullOrEmpty(request.Name))
                product.Name = request.Name;
            if (!string.IsNullOrEmpty(request.ShortDescription))
                product.ShortDescription = request.ShortDescription;
            if (!string.IsNullOrEmpty(request.FullDescription))
                product.FullDescription = request.FullDescription;
            if (request.Price.HasValue)
                product.Price = request.Price.Value;
            if (request.StockQuantity.HasValue)
            {
                product.StockQuantity = request.StockQuantity.Value;
                //stock management must be enabled for the quantity to have an effect
                product.ManageInventoryMethodId = (int)ManageInventoryMethod.ManageStock;
            }
            if (request.Published.HasValue)
                product.Published = request.Published.Value;

            product.Sku = request.Sku;

            if (isNew)
                await _productService.InsertProductAsync(product);
            else
                await _productService.UpdateProductAsync(product);

            return JsonResult(StatusCodes.Status200OK, new { sku = request.Sku, productId = product.Id, created = isNew });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Business Central product push failed for SKU {Sku}", request.Sku);

            return JsonResult(StatusCodes.Status500InternalServerError, new { error = "Product push failed" });
        }
    }

    /// <summary>
    /// Returns new/changed orders since the given timestamp (polled by Business Central to create sales orders)
    /// </summary>
    public virtual async Task<IActionResult> Orders()
    {
        if (!await IsApiKeyValidAsync())
            return JsonResult(StatusCodes.Status401Unauthorized, new { error = "Invalid API key" });

        try
        {
            var since = ParseSince();
            var pageSize = ParseMax();

            var orders = await _orderService.SearchOrdersAsync(createdFromUtc: since, pageIndex: 0, pageSize: pageSize);

            var response = new OrderExportResponse { Total = orders.TotalCount };

            foreach (var order in orders)
            {
                var billing = order.BillingAddressId > 0
                    ? await BuildAddressAsync(await _addressService.GetAddressByIdAsync(order.BillingAddressId))
                    : null;
                var shipping = order.ShippingAddressId.HasValue
                    ? await BuildAddressAsync(await _addressService.GetAddressByIdAsync(order.ShippingAddressId.Value))
                    : null;

                var orderItems = await _orderService.GetOrderItemsAsync(order.Id);

                //load products in one batch for the SKU mapping
                var productIds = orderItems.Select(item => item.ProductId).Distinct().ToArray();
                var products = await _productService.GetProductsByIdsAsync(productIds);
                var productById = products.ToDictionary(product => product.Id, product => product);

                var dto = new OrderExportDto
                {
                    Id = order.Id,
                    OrderNumber = string.IsNullOrEmpty(order.CustomOrderNumber) ? order.Id.ToString() : order.CustomOrderNumber,
                    CreatedOnUtc = order.CreatedOnUtc,
                    OrderStatusId = order.OrderStatusId,
                    PaymentStatusId = order.PaymentStatusId,
                    ShippingStatusId = order.ShippingStatusId,
                    CurrencyCode = order.CustomerCurrencyCode,
                    SubtotalInclTax = order.OrderSubtotalInclTax,
                    OrderTotal = order.OrderTotal,
                    CustomerEmail = billing?.Email,
                    BillingAddress = billing,
                    ShippingAddress = shipping
                };

                foreach (var item in orderItems)
                {
                    productById.TryGetValue(item.ProductId, out var product);

                    dto.Items.Add(new OrderExportItemDto
                    {
                        Sku = product?.Sku ?? item.ProductId.ToString(),
                        ProductName = product?.Name ?? item.ProductId.ToString(),
                        Quantity = item.Quantity,
                        UnitPriceInclTax = item.UnitPriceInclTax,
                        UnitPriceExclTax = item.UnitPriceExclTax,
                        LineTotalInclTax = item.PriceInclTax
                    });
                }

                response.Orders.Add(dto);
            }

            return JsonResult(StatusCodes.Status200OK, response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Business Central order export failed");

            return JsonResult(StatusCodes.Status500InternalServerError, new { error = "Order export failed" });
        }
    }

    /// <summary>
    /// Returns new/changed customers since the given timestamp (polled by Business Central to create customers)
    /// </summary>
    public virtual async Task<IActionResult> Customers()
    {
        if (!await IsApiKeyValidAsync())
            return JsonResult(StatusCodes.Status401Unauthorized, new { error = "Invalid API key" });

        try
        {
            var since = ParseSince();
            var pageSize = ParseMax();

            var customers = await _customerService.GetAllCustomersAsync(createdFromUtc: since, pageIndex: 0, pageSize: pageSize);

            var response = new CustomerExportResponse { Total = customers.TotalCount };
            response.Customers = customers.Select(customer => new CustomerExportDto
            {
                Id = customer.Id,
                Email = customer.Email,
                Username = customer.Username,
                CustomerGuid = customer.CustomerGuid,
                CreatedOnUtc = customer.CreatedOnUtc,
                Active = customer.Active
            }).ToList();

            return JsonResult(StatusCodes.Status200OK, response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Business Central customer export failed");

            return JsonResult(StatusCodes.Status500InternalServerError, new { error = "Customer export failed" });
        }
    }

    /// <summary>
    /// Exports the store languages (used by the Business Central shop setup to maintain
    /// the per-shop language whitelist and the default language of each shop)
    /// </summary>
    public virtual async Task<IActionResult> Languages()
    {
        if (!await IsApiKeyValidAsync())
            return JsonResult(StatusCodes.Status401Unauthorized, new { error = "Invalid API key" });

        try
        {
            var languages = await _languageService.GetAllLanguagesAsync(showHidden: true);

            var response = new LanguageExportResponse
            {
                Total = languages.Count,
                Languages = languages.Select(language => new LanguageExportDto
                {
                    Id = language.Id,
                    Name = language.Name,
                    LanguageCulture = language.LanguageCulture,
                    UniqueSeoCode = language.UniqueSeoCode,
                    Rtl = language.Rtl,
                    Published = language.Published,
                    DisplayOrder = language.DisplayOrder
                }).ToList()
            };

            return JsonResult(StatusCodes.Status200OK, response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Business Central language export failed");

            return JsonResult(StatusCodes.Status500InternalServerError, new { error = "Language export failed" });
        }
    }

    #endregion
}
