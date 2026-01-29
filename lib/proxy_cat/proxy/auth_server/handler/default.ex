defmodule ProxyCat.Proxy.AuthServer.Handler.Default do
  @behaviour ProxyCat.Proxy.AuthServer.Handler

  @impl ProxyCat.Proxy.AuthServer.Handler
  def init(_), do: %{}

  @impl ProxyCat.Proxy.AuthServer.Handler
  def handle_info(_message, state) do
    state
  end

  @impl ProxyCat.Proxy.AuthServer.Handler
  def store(state, key, value) do
    Map.put(state, key, value)
  end

  @impl ProxyCat.Proxy.AuthServer.Handler
  def retrieve(state, key) do
    Map.get(state, key)
  end
end
