namespace Nop.Plugin.Misc.BusinessCentral.Services;

/// <summary>
/// Represents the result of a catalog synchronization run
/// </summary>
public class BusinessCentralSyncResult
{
    /// <summary>
    /// Gets or sets the number of products created in nopCommerce
    /// </summary>
    public int Created { get; set; }

    /// <summary>
    /// Gets or sets the number of existing products updated in nopCommerce
    /// </summary>
    public int Updated { get; set; }

    /// <summary>
    /// Gets or sets the number of items that were already up to date (or skipped)
    /// </summary>
    public int Skipped { get; set; }

    /// <summary>
    /// Gets the errors that occurred while processing single items (key: SKU)
    /// </summary>
    public IList<string> Errors { get; } = new List<string>();
}
