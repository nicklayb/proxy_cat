defmodule ProxyCat.Config.V1.Config.Proxy.Headers do
  @moduledoc """
  Headers conversion definition
  """
  use Starchoice.Decoder

  alias ProxyCat.Config.V1.Config.Proxy.Headers

  defstruct add: [], drop: [], drop_all: false

  @type t :: %Headers{
          add: [{String.t(), String.t()}],
          drop: [String.t()],
          drop_all: boolean()
        }

  defdecoder do
    field(:add, with: &Headers.to_tuple/1, default: [])
    field(:drop, default: [])
    field(:drop_all, default: false)
  end

  @doc "Converts mapping of headers to tuples"
  @spec to_tuple(map()) :: {String.t(), String.t()}
  def to_tuple(%{"key" => key, "value" => value}) do
    {key, value}
  end
end
