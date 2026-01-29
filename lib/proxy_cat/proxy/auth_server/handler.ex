defmodule ProxyCat.Proxy.AuthServer.Handler do
  @callback init(struct()) :: {:ok, map()}
  @callback store(map(), atom(), any()) :: map()
  @callback retrieve(map(), atom()) :: map()

  @callback handle_info(any(), map()) :: map()
end
