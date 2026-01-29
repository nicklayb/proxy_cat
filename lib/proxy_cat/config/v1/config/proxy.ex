defmodule ProxyCat.Config.V1.Config.Proxy do
  @moduledoc """
  Proxy definition
  """
  use Starchoice.Decoder

  alias ProxyCat.Config.AuthSpec
  alias ProxyCat.Config.CacheSpec
  alias ProxyCat.Config.V1.Config.Proxy.Headers

  defstruct [:key, :host, :request_headers, :response_headers, :auth, :cache]

  @type t :: %ProxyCat.Config.V1.Config.Proxy{
          key: String.t(),
          host: URI.t(),
          request_headers: Headers.t(),
          response_headers: Headers.t(),
          auth: AuthSpec.t()
        }

  defdecoder do
    field(:key)
    field(:host, with: &URI.parse/1)
    field(:request_headers, with: Headers, default: %Headers{})
    field(:response_headers, with: Headers, default: %Headers{})
    field(:auth, with: &AuthSpec.decode/1)
    field(:cache, with: CacheSpec)
  end
end
