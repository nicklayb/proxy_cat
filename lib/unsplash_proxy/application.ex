defmodule UnsplashProxy.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      UnsplashProxy.Server
    ]

    opts = [strategy: :one_for_one, name: UnsplashProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
