defmodule ProxyCat.Config.V1.Config.Proxy.Headers do
  defstruct add: [], drop: [], drop_all: false
  use Starchoice.Decoder
  alias ProxyCat.Config.V1.Config.Proxy.Headers

  defdecoder do
    field(:add, with: &Headers.to_tuple/1, default: [])
    field(:drop, default: [])
    field(:drop_all, default: false)
  end

  def to_tuple(list) when is_list(list) do
    Enum.map(list, &to_tuple/1)
  end

  def to_tuple(%{"key" => key, "value" => value}) do
    {key, value}
  end
end
