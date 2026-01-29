defmodule ProxyCat.Proxy.StateServer do
  alias ProxyCat.Proxy.AuthServer
  use Supervisor

  defdelegate store(proxy_key, key, value), to: AuthServer
  defdelegate retrieve(proxy_key, key), to: AuthServer
  defdelegate retrieve_all(proxy_key, keys), to: AuthServer

  @name __MODULE__
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @impl Supervisor
  def init(_init_arg) do
    children = children(ProxyCat.Config.Server.config())
    Supervisor.init(children, strategy: :one_for_one)
  end

  def clear(proxy_key, key) do
    store(proxy_key, key, nil)
  end

  defp children(config) do
    config
    |> ProxyCat.Config.Interface.stateful_proxies()
    |> Enum.map(fn {auth_spec, key} ->
      full_name = AuthServer.qualify_name(key)

      {AuthServer, [key: key, auth_spec: auth_spec, name: full_name]}
    end)
  end
end
