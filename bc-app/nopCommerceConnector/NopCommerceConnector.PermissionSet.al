namespace NopCommerceConnector;

/// <summary>
/// Access permission set for the nopCommerce Connector tables.
/// Required by the cloud deployment validation (PerTenantExtensionCop rule PTE0004:
/// every table of a per-tenant extension needs a matching permission set).
/// Assign it to users who operate the nopCommerce integration without full (SUPER) permissions.
/// </summary>
permissionset 62110 "Nop Commerce Access"
{
    Assignable = true;

    Permissions =
        tabledata "Nop Commerce Shop" = rimd,
        tabledata "Nop Product" = rimd,
        tabledata "Nop Product Filter" = rimd;
}
