defmodule ProxyCat.Routing.V1.Config.Proxy do
  defstruct [:key, :host, :headers, :auth]
  use Starchoice.Decoder
  alias ProxyCat.Routing.V1.Config.Proxy.Headers
  alias ProxyCat.Routing.AuthSpec

  defdecoder do
    field(:key)
    field(:host, with: &URI.parse/1)
    field(:headers, with: Headers, default: %Headers{})
    field(:auth, with: &AuthSpec.decode/1)
  end
end
