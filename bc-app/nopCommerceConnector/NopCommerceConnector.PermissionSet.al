namespace NopCommerceConnector;

/// <summary>
/// Access permission set for the nopCommerce Connector (tables and codeunits).
/// Required by the cloud deployment validation (PerTenantExtensionCop rule PTE0004:
/// every table of a per-tenant extension needs a matching permission set) and by
/// Business Central implicit permissions (codeunits need Execute = permission kind "X"
/// for users without SUPER — e.g. "Nop Commerce Http", "Nop Commerce Mgt.").
/// Assign it to users who operate the nopCommerce integration without full (SUPER) permissions.
/// </summary>
permissionset 62110 "Nop Commerce Access"
{
    Assignable = true;

    Permissions =
        codeunit "Nop Commerce Mgt." = X,
        codeunit "Nop Store Products" = X,
        codeunit "Nop Commerce Http" = X,
        tabledata "Nop Commerce Shop" = rimd,
        tabledata "Nop Product" = rimd,
        tabledata "Nop Product Filter" = rimd,
        tabledata "Nop Language" = rimd,
        tabledata "Nop Commerce Cue" = rimd,
        tabledata "Nop Customer" = rimd,
        tabledata "Nop Customer Login" = rimd;
}
