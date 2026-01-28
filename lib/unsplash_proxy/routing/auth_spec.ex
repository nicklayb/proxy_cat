defmodule ProxyCat.Routing.AuthSpec do
  defmodule Oauth2 do
    @url_fields [:authorize_url, :token_url]
    @fields [:client_id, :response_type, :client_secret, :grant_type, :scopes, :refresh_token]
    defstruct @fields ++ @url_fields
    use Starchoice.Decoder

    defdecoder do
      Enum.map(@fields, &field/1)
      Enum.map(@url_fields, fn field -> field(field, with: &URI.parse/1) end)
    end

    def authorize_url(
          %Oauth2{
            authorize_url: authorize_url,
            client_id: client_id,
            scopes: scopes,
            response_type: response_type
          },
          redirect_uri
        ) do
      query =
        Enum.reduce(
          [
            client_id: client_id,
            scope: scopes,
            redirect_uri: redirect_uri,
            response_type: response_type
          ],
          %{},
          fn {key, value}, acc ->
            Map.put(acc, key, ProxyCat.VariableInjector.inject(value))
          end
        )

      %URI{authorize_url | query: URI.encode_query(query)}
    end

    def token_call_spec(
          %Oauth2{
            token_url: token_url,
            client_id: client_id,
            client_secret: client_secret,
            scopes: scopes,
            grant_type: grant_type
          },
          code,
          redirect_uri
        ) do
      form_body = %{
        client_id: client_id,
        client_secret: client_secret,
        code: code,
        grant_type: grant_type,
        scope: scopes,
        redirect_uri: redirect_uri
      }

      {token_url, form_body}
    end
  end

  def decode(%{"type" => "oauth2"} = body) do
    Starchoice.decode!(body, Oauth2)
  end

  def decode(_), do: nil
end
