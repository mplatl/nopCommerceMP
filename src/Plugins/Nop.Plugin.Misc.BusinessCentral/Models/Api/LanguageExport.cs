namespace Nop.Plugin.Misc.BusinessCentral.Models.Api;

/// <summary>
/// Response of the language export endpoint (consumed by the Business Central extension)
/// </summary>
public class LanguageExportResponse
{
    /// <summary>
    /// Gets or sets the total number of languages
    /// </summary>
    public int Total { get; set; }

    /// <summary>
    /// Gets or sets the exported languages
    /// </summary>
    public IList<LanguageExportDto> Languages { get; set; } = new List<LanguageExportDto>();
}

/// <summary>
/// Represents a nopCommerce language snapshot for the Business Central shop setup
/// (per-shop whitelist of languages, default language of the shop, localized texts)
    /// </summary>
public class LanguageExportDto
{
    /// <summary>
    /// Gets or sets the language identifier
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Gets or sets the language name
    /// </summary>
    public string Name { get; set; }

    /// <summary>
    /// Gets or sets the language culture (e.g. de-AT, en-US)
    /// </summary>
    public string LanguageCulture { get; set; }

    /// <summary>
    /// Gets or sets the unique SEO code (e.g. de, en)
    /// </summary>
    public string UniqueSeoCode { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether the language is right-to-left
    /// </summary>
    public bool Rtl { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether the language is published
    /// </summary>
    public bool Published { get; set; }

    /// <summary>
    /// Gets or sets the display order
    /// </summary>
    public int DisplayOrder { get; set; }
}
