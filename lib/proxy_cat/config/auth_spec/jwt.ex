defmodule ProxyCat.Config.AuthSpec.Jwt do
  @url_fields [:refresh_url]
  @fields [:access_token, :client_id, :refresh_token]
  defstruct @fields ++ @url_fields

  use Starchoice.Decoder

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
