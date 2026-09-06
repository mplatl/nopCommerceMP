namespace NopCommerceConnector;

/// <summary>
/// Thin HTTP transport for the nopCommerce plugin API of a shop.
/// Business Central is the orchestrator: it calls the plugin endpoints (X-Api-Key header);
/// nopCommerce never initiates requests. GET is used for pulls (health, languages export);
/// POST (products push) follows together with the product sync iteration.
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
        exit(Send(Shop, 'GET', UrlPath, ResponseText));
    end;

    /// <summary>
    /// Sends a request to the plugin API of the shop (method GET/POST, X-Api-Key header).
    /// </summary>
    internal procedure Send(Shop: Record "Nop Commerce Shop"; Method: Text; UrlPath: Text; var ResponseText: Text) Success: Boolean
    var
        HttpClient: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
    begin
        Shop.ValidateSetup();

        Request.SetRequestUri(BuildUrl(Shop, UrlPath));
        Request.Method := Method;
        Request.GetHeaders(Headers);
        Headers.Add('X-Api-Key', Shop."API Key");

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
