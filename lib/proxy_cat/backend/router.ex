defmodule ProxyCat.Backend.Router do
  @moduledoc """
  Backend router that serves as a backoffice service.
  This router is hosted in a seperate web server (with
  a different port) so that anything that is not "proxy
  handling" should go through it.
  """
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get("oauth/callback/:key", to: ProxyCat.Backend.OauthHandler)

  match(_) do
    send_resp(conn, 400, "Not found")
  end

  @doc "Generates oauth callback for the given proxy target"
  @spec oauth_callback(atom()) :: String.t()
  def oauth_callback(target), do: path("/oauth/callback/#{target}")

  @doc "Builds path for the configured host"
  @spec path([String.t()] | String.t(), map()) :: String.t()
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
