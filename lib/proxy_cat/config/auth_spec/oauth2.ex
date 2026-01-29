defmodule ProxyCat.Config.AuthSpec.Oauth2 do
  @url_fields [:authorize_url, :token_url]
  @fields [:client_id, :response_type, :client_secret, :grant_type, :scopes, :refresh_token]
  defstruct @fields ++ @url_fields
  use Starchoice.Decoder
  alias ProxyCat.Backend.Router
  alias ProxyCat.Config.AuthSpec.Oauth2

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
        target_proxy
      ) do
    query =
      %{
        client_id: client_id,
        scope: scopes,
        redirect_uri: Router.oauth_callback(target_proxy),
        response_type: response_type
      }

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
        target_proxy
      ) do
    form_body =
      %{
        client_id: client_id,
        client_secret: client_secret,
        code: code,
        grant_type: grant_type,
        scope: scopes,
        redirect_uri: Router.oauth_callback(target_proxy)
      }

    {token_url, form_body}
  end
end
