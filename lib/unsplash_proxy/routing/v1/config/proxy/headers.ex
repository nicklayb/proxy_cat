defmodule ProxyCat.Routing.V1.Config.Proxy.Headers do
  defstruct add: [], drop: []
  use Starchoice.Decoder
  alias ProxyCat.Routing.V1.Config.Proxy.Headers

  defdecoder do
    field(:add, with: &Headers.to_tuple/1, default: [])
    field(:drop, default: [])
  end

  def to_tuple(list) when is_list(list) do
    Enum.map(list, &to_tuple/1)
  end

  def to_tuple(%{"key" => key, "value" => value}) do
    {key, value}
  end
end
