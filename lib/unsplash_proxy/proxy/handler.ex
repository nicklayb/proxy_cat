defmodule ProxyCat.Proxy.Handler do
  alias ProxyCat.Proxy.StateServer
  alias ProxyCat.Routing.AuthSpec.Oauth2
  alias ProxyCat.Cache
  require Logger

  def init(_args) do
    []
  end

  def call(%Plug.Conn{} = conn, _) do
    config = ProxyCat.Routing.Server.config()

    with {:ok, %{host: host, target: target, auth: auth, headers: headers}} <-
           fetch_proxy_config(config, conn) do
      call_target(conn, config, target, host, headers, auth)
    end
  end

  defp call_target(%Plug.Conn{} = conn, config, target, %URI{} = host, headers, auth) do
    method = to_atom_method(conn.method)

    path =
      case conn.path_info do
        [] -> ""
        parts -> Path.join(parts)
      end

    uri = %URI{host | path: "/" <> path, query: conn.query_string}

    auth_headers = auth_headers(target, auth)

    with {:ok, response} <- request(method, uri, auth_headers ++ headers) do
      respond_from_response(conn, uri, config, target, response)
    end
  end

  defp auth_headers(target, {:ok, %Oauth2{}}) do
    %{access_token: access_token, token_type: token_type} =
      StateServer.retrieve_all(target, [:access_token, :token_type])

    [{"Authorization", "#{token_type} #{access_token}"}]
  end

  defp auth_headers(_, _), do: []

  defp request(method, uri, headers) do
    Cache.cached(cache_key(uri), [cache_match: &should_cache?/1], fn ->
      Logger.info("[#{inspect(__MODULE__)}.Req] [#{method}] [#{uri.path}] [#{uri.query}]")

      Req.request(method: method, url: uri, headers: headers, decode_body: false)
    end)
  end

  defp should_cache?({:ok, %Req.Response{status: status}}) do
    status in 200..299
  end

  defp should_cache?(_) do
    false
  end

  defp cache_key(%URI{path: path, query: query}) do
    :sha256
    |> :crypto.hash("#{path}?#{query}")
    |> Base.encode16()
    |> String.downcase()
  end

  defp respond_from_response(conn, %URI{} = uri, config, target, %Req.Response{} = response) do
    Logger.debug(
      "[#{inspect(__MODULE__)}.Req] [#{response.status}] [#{uri.path}] [#{inspect(response.headers)}]"
    )

    config
    |> ProxyCat.Routing.Interface.update_headers(target, :response, response.headers)
    |> Enum.reduce(conn, fn {key, value}, acc ->
      Plug.Conn.put_resp_header(acc, key, Enum.join(value, ";"))
    end)
    |> Plug.Conn.resp(response.status, response.body)
    |> Plug.Conn.send_resp()
  end

  defp to_atom_method(method) do
    method
    |> String.downcase()
    |> String.to_existing_atom()
  end

  @target_header String.downcase("X-ProxyCat-Target")
  defp fetch_proxy_config(config, conn) do
    with {:ok, target} <- get_target_header(conn),
         {:proxy, true} <- {:proxy, ProxyCat.Routing.Interface.proxy_exists?(config, target)},
         {:ok, host} <- ProxyCat.Routing.Interface.host(config, target) do
      headers =
        config
        |> ProxyCat.Routing.Interface.update_headers(target, :request, conn.req_headers)
        |> Enum.reject(fn {key, _} -> key == @target_header end)

      auth = ProxyCat.Routing.Interface.auth(config, target)

      {:ok, %{target: target, host: host, headers: headers, auth: auth}}
    else
      {:proxy, false} ->
        {:error, :not_found}

      error ->
        error
    end
  end

  defp get_target_header(%Plug.Conn{} = conn) do
    case Plug.Conn.get_req_header(conn, @target_header) do
      [value | _] ->
        {:ok, String.to_existing_atom(value)}

      _ ->
        {:error, :not_found}
    end
  rescue
    _ ->
      {:error, :invalid_target}
  end
end
