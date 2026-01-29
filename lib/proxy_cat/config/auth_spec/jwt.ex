defmodule ProxyCat.Config.AuthSpec.Jwt do
  @moduledoc """
  Authentication spec for the JWT mechanism. The way we
  manage JWT tokens is by expecting the following keys:

  - `access_token`: Access token used to do actual requests
  - `refresh_token`: Refresh token used to refresh the tokens after expiration
  - `client_id`: Client ID to send to the server.
  - `refresh_url`: URL used to refresh the tokens.
  """
  use Starchoice.Decoder

  @url_fields [:refresh_url]
  @fields [:access_token, :client_id, :refresh_token]
  defstruct @fields ++ @url_fields

  @type t :: %ProxyCat.Config.AuthSpec.Jwt{
          refresh_url: URI.t(),
          access_token: String.t(),
          client_id: String.t(),
          refresh_token: String.t()
        }

  defdecoder do
    Enum.map(@fields, &field/1)
    Enum.map(@url_fields, fn field -> field(field, with: &URI.parse/1) end)
  end
end
