defmodule ProxyCat.Application do
  @moduledoc """
  Main application tree
  """
  use Application

  @impl Application
  def start(_type, _args) do
    children =
      if env() != :test do
        [
          ProxyCat.Config.Server,
          ProxyCat.Proxy.StateServer,
          {Box.Cache.Server, name: ProxyCat.Cache},
          web_server(ProxyCat.Proxy.Handler),
          web_server(ProxyCat.Backend.Router)
        ]
      else
        []
      end

    opts = [strategy: :rest_for_one, name: ProxyCat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp web_server(handler, args \\ []) do
    port =
      :proxy_cat
      |> Application.fetch_env!(handler)
      |> Keyword.fetch!(:port)

    args = Keyword.merge([plug: handler, scheme: :http, port: port], args)

    Bandit.child_spec(args)
  end

  defp env do
    Application.fetch_env!(:proxy_cat, :environment)
  end
end
