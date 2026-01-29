defmodule ProxyCat.Proxy.StateServer do
  @moduledoc """
  Holds states for any stateful proxies such as ones with
  authentication. These proxies are required to keep a token
  in memory for subsequent calls so these server holds them.

  This modules supervises the servers and is an entrypoint
  module for those so that caller don't need to bother who 
  they're expected to call.
  """
  use Supervisor

  alias ProxyCat.Proxy.AuthServer

  defdelegate store(proxy_key, key, value), to: AuthServer
  defdelegate retrieve(proxy_key, key), to: AuthServer
  defdelegate retrieve_all(proxy_key, keys), to: AuthServer

  @name __MODULE__
  @doc "Starts the state server supervisor"
  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(_args) do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @impl Supervisor
  def init(_init_arg) do
    children = children(ProxyCat.Config.current())
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp children(config) do
    config
    |> ProxyCat.Config.stateful_proxies()
    |> Enum.map(fn {auth_spec, key} ->
      full_name = AuthServer.qualify_name(key)

      {AuthServer, [key: key, auth_spec: auth_spec, name: full_name]}
    end)
  end
end
