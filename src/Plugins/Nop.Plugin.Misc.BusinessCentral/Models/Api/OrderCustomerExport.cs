namespace Nop.Plugin.Misc.BusinessCentral.Models.Api;

/// <summary>
/// Response of the order export endpoint (consumed by the Business Central extension)
/// </summary>
public class OrderExportResponse
{
    /// <summary>
    /// Gets or sets the total number of matching orders
    /// </summary>
    public int Total { get; set; }

    /// <summary>
    /// Gets or sets the exported orders
    /// </summary>
    public IList<OrderExportDto> Orders { get; set; } = new List<OrderExportDto>();
}

/// <summary>
/// Represents an order snapshot for the Business Central sales order import
/// </summary>
public class OrderExportDto
{
    public int Id { get; set; }
    public string OrderNumber { get; set; }
    public DateTime? CreatedOnUtc { get; set; }
    public int OrderStatusId { get; set; }
    public int PaymentStatusId { get; set; }
    public int ShippingStatusId { get; set; }
    public string CurrencyCode { get; set; }
    public decimal SubtotalInclTax { get; set; }
    public decimal OrderTotal { get; set; }
    public string CustomerEmail { get; set; }
    public OrderAddressDto BillingAddress { get; set; }
    public OrderAddressDto ShippingAddress { get; set; }
    public IList<OrderExportItemDto> Items { get; set; } = new List<OrderExportItemDto>();
}

/// <summary>
/// Represents an order line for the Business Central sales order import
/// </summary>
public class OrderExportItemDto
{
    public string Sku { get; set; }
    public string ProductName { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPriceInclTax { get; set; }
    public decimal UnitPriceExclTax { get; set; }
    public decimal LineTotalInclTax { get; set; }
}

/// <summary>
/// Represents a billing/shipping address snapshot
/// </summary>
public class OrderAddressDto
{
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string Company { get; set; }
    public string Address1 { get; set; }
    public string Address2 { get; set; }
    public string City { get; set; }
    public string ZipPostalCode { get; set; }
    public string Country { get; set; }
    public string State { get; set; }
    public string Phone { get; set; }
    public string Email { get; set; }
}

/// <summary>
/// Response of the customer export endpoint (consumed by the Business Central extension)
/// </summary>
public class CustomerExportResponse
{
    /// <summary>
    /// Gets or sets the total number of matching customers
    /// </summary>
    public int Total { get; set; }

    /// <summary>
    /// Gets or sets the exported customers
    /// </summary>
    public IList<CustomerExportDto> Customers { get; set; } = new List<CustomerExportDto>();
}

/// <summary>
/// Represents a customer snapshot for the Business Central customer import
/// </summary>
public class CustomerExportDto
{
    public int Id { get; set; }
    public string Email { get; set; }
    public string Username { get; set; }
    public Guid CustomerGuid { get; set; }
    public DateTime? CreatedOnUtc { get; set; }
    public bool Active { get; set; }
}
