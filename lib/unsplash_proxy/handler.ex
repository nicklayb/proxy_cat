defmodule UnsplashProxy.Handler do
  require Logger

  def init(_), do: []

  @unsplash_host URI.parse("https://api.unsplash.com")

  def call(%Plug.Conn{} = conn, _opts) do
    method = to_atom_method(conn.method)

    path =
      case conn.path_info do
        [] -> ""
        parts -> Path.join(conn.path_info)
      end

    uri = %URI{@unsplash_host | path: path, query: conn.query_string}

    with {:ok, response} <-
           Req.request(method: method, url: uri, headers: headers(), raw: true) do
      respond_from_response(conn, response)
    end
  end

  defp respond_from_response(conn, %Req.Response{} = response) do
    Logger.debug(
      "[#{inspect(__MODULE__)}.Req] [#{response.status}] [#{inspect(response.headers)}]"
    )

    response.headers
    |> Enum.reduce(conn, fn {key, value}, acc ->
      Plug.Conn.put_resp_header(acc, key, Enum.join(value, ";"))
    end)
    |> Plug.Conn.send_resp(response.status, response.body)
  end

  defp headers do
    api_key = unsplash_api_key()

    [
      {"Authorization", "Client-ID #{api_key}"},
      {"Accept-Version", "v1"}
    ]
  end

  defp unsplash_api_key do
    :unsplash_proxy
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:unsplash_api_key)
  end

  defp to_atom_method(method) do
    method
    |> String.downcase()
    |> String.to_existing_atom()
  end
end
