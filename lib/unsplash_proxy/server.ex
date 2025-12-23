defmodule UnsplashProxy.Server do
  def child_spec(args) do
    port =
      :unsplash_proxy
      |> Application.fetch_env!(__MODULE__)
      |> Keyword.fetch!(:port)

    args = Keyword.merge([plug: UnsplashProxy.Handler, scheme: :http, port: port], args)

    Bandit.child_spec(args)
  end
end
