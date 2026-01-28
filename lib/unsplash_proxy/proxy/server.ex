defmodule ProxyCat.Proxy.Server do
  def child_spec(args) do
    port =
      :proxy_cat
      |> Application.fetch_env!(__MODULE__)
      |> Keyword.fetch!(:port)

    args =
      Keyword.merge(
        [
          plug: ProxyCat.Proxy.Handler,
          scheme: :http,
          port: port
        ],
        args
      )

    Bandit.child_spec(args)
  end
end
