defmodule ProxyCat.Config.AuthSpec.Oauth2 do
  @moduledoc """
  Authentication Spec for the OAuth2 with callback
  mechanism. This is cases where auth expects you
  to redirect the user to an Authorize page then
  return to your callback url with a code.

  It expects the following configuration:

  - `authorize_url`: URL to call to ask the user for authorization
  - `token_url`: URL to call, using code obtained by `authorize_url` to obtain tokens.
  - `client_id`: Client ID of the OAuth application
  - `client_secret`: Client secret of the OAuth application
  - `grant_type`: Type of grant to request the server
  - `scopes`: The permission scopes
  - `refresh_token`: If the server supports refresh token or not.
  """
  use Starchoice.Decoder

  alias ProxyCat.Backend.Router
  alias ProxyCat.Config.AuthSpec.Oauth2

  @url_fields [:authorize_url, :token_url]
  @fields [:client_id, :response_type, :client_secret, :grant_type, :scopes, :refresh_url]
  defstruct @fields ++ @url_fields

  @type t :: %ProxyCat.Config.AuthSpec.Oauth2{
          authorize_url: URI.t(),
          token_url: URI.t(),
          client_id: String.t(),
          response_type: String.t(),
          client_secret: String.t(),
          grant_type: String.t(),
          scopes: String.t(),
          refresh_url: URI.t() | nil
        }

  defdecoder do
    Enum.map(@fields, &field/1)
    Enum.map(@url_fields, fn field -> field(field, with: &URI.parse/1) end)
  end

  @doc "Builds authorize url with the callback url"
  @spec authorize_url(t(), atom()) :: URI.t()
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

  @doc "Builds token call spec with the callback url. It also returns form body"
  @spec token_call_spec(t(), String.t(), atom()) :: {URI.t(), map()}
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
