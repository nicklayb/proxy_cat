defmodule ProxyCat.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ProxyCat.Routing.Server,
      ProxyCat.Proxy.StateServer,
      {Box.Cache.Server, name: ProxyCat.Cache},
      ProxyCat.Proxy.Server,
      ProxyCat.Backend.Server
    ]

    opts = [strategy: :one_for_one, name: ProxyCat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
