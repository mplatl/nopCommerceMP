namespace NopCommerceConnector;

/// <summary>
/// Thin HTTP transport for the nopCommerce plugin API of a shop.
/// Business Central is the orchestrator: it calls the plugin endpoints (X-Api-Key header);
/// nopCommerce never initiates requests.
/// GET  = pulls (health, languages export, later orders/customers)
/// POST = pushes (product catalog export)
/// </summary>
codeunit 62120 "Nop Commerce Http"
{
    /// <summary>
    /// Executes a GET request against the plugin API of the shop.
    /// </summary>
    /// <param name="Shop">The shop whose connection is used.</param>
    /// <param name="UrlPath">API path relative to the shop URL, e.g. api/bc/languages.</param>
    /// <param name="ResponseText">Response body (also filled on HTTP errors).</param>
    /// <returns>True if the request was sent and answered with an HTTP success code.</returns>
    internal procedure Get(Shop: Record "Nop Commerce Shop"; UrlPath: Text; var ResponseText: Text): Boolean
    begin
        exit(Send(Shop, 'GET', UrlPath, '', ResponseText));
    end;

    /// <summary>
    /// Executes a POST request with a JSON body against the plugin API of the shop.
    /// </summary>
    /// <param name="Shop">The shop whose connection is used.</param>
    /// <param name="UrlPath">API path relative to the shop URL, e.g. api/bc/products.</param>
    /// <param name="JsonBody">JSON payload of the request.</param>
    /// <param name="ResponseText">Response body (also filled on HTTP errors).</param>
    /// <returns>True if the request was sent and answered with an HTTP success code.</returns>
    internal procedure Post(Shop: Record "Nop Commerce Shop"; UrlPath: Text; JsonBody: Text; var ResponseText: Text): Boolean
    begin
        exit(Send(Shop, 'POST', UrlPath, JsonBody, ResponseText));
    end;

    /// <summary>
    /// Sends a request to the plugin API of the shop (X-Api-Key header, optional JSON body).
    /// </summary>
    internal procedure Send(Shop: Record "Nop Commerce Shop"; Method: Text; UrlPath: Text; JsonBody: Text; var ResponseText: Text) Success: Boolean
    var
        HttpClient: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
    begin
        Shop.ValidateSetup();

        Request.SetRequestUri(BuildUrl(Shop, UrlPath));
        Request.Method := Method;
        Request.GetHeaders(Headers);
        Headers.Add('X-Api-Key', Shop."API Key");

        if Method in ['POST', 'PUT'] then begin
            Content.WriteFrom(JsonBody);
            Content.GetHeaders(ContentHeaders);
            if ContentHeaders.Contains('Content-Type') then
                ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/json');
            Request.Content(Content);
        end;

        if HttpClient.Send(Request, Response) then begin
            Success := Response.IsSuccessStatusCode();
            ReadContent(Response, ResponseText);
        end else
            ResponseText := 'The request could not be sent.';
    end;

    [TryFunction]
    local procedure ReadContent(Response: HttpResponseMessage; var ResponseText: Text)
    var
        Content: HttpContent;
    begin
        Content := Response.Content();
        Content.ReadAs(ResponseText);
    end;

    local procedure BuildUrl(Shop: Record "Nop Commerce Shop"; UrlPath: Text): Text
    var
        BaseUrl: Text;
    begin
        BaseUrl := Shop."Nop Commerce URL";
        if BaseUrl.EndsWith('/') then
            BaseUrl := CopyStr(BaseUrl, 1, StrLen(BaseUrl) - 1);

        exit(BaseUrl + '/' + UrlPath);
    end;
}
