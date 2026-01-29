defmodule ProxyCat.Backend.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("oauth/callback/:key", to: ProxyCat.Backend.OauthHandler)

  match(_) do
    send_resp(conn, 400, "Not found")
  end

  def oauth_callback(target), do: path("/oauth/callback/#{target}")

  def path(path, query \\ %{})

  def path(path, query) when is_list(path) do
    path
    |> Path.join()
    |> then(&path("/" <> &1, query))
  end

  def path(path, query) do
    query = URI.encode_query(query)
    uri = %URI{host() | path: path, query: query}
    URI.to_string(uri)
  end

  defp host do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:host)
  end
end
