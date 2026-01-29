defmodule ProxyCat.Config.AuthSpec.Jwt do
  @url_fields [:refresh_url]
  @fields [:access_token, :client_id, :refresh_token]
  defstruct @fields ++ @url_fields

  use Starchoice.Decoder

  defdecoder do
    Enum.map(@fields, &field/1)
    Enum.map(@url_fields, fn field -> field(field, with: &URI.parse/1) end)
  end
end
