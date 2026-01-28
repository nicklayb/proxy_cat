defmodule ProxyCat.Proxy.Handler do
  alias ProxyCat.Cache
  require Logger

  def init(_args) do
    config = ProxyCat.Routing.Server.config()
    %{config: config}
  end

  def call(%Plug.Conn{} = conn, %{config: config}) do
    with {:ok, %{host: host, headers: headers}} <- fetch_proxy_config(config, conn) do
      call_target(conn, host, headers)
    end
  end

  defp call_target(%Plug.Conn{} = conn, %URI{} = host, headers) do
    method = to_atom_method(conn.method)

    path =
      case conn.path_info do
        [] -> ""
        parts -> Path.join(parts)
      end

    uri = %URI{host | path: path, query: conn.query_string}

    with {:ok, response} <- request(method, uri, headers) do
      respond_from_response(conn, uri, response)
    end
  end

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

  defp respond_from_response(conn, %URI{} = uri, %Req.Response{} = response) do
    Logger.debug(
      "[#{inspect(__MODULE__)}.Req] [#{response.status}] [#{uri.path}] [#{inspect(response.headers)}]"
    )

    response.headers
    |> Enum.reduce(conn, fn {key, value}, acc ->
      Plug.Conn.put_resp_header(acc, key, Enum.join(value, ";"))
    end)
    |> Plug.Conn.send_resp(response.status, response.body)
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
        |> ProxyCat.Routing.Interface.update_headers(target, conn.req_headers)
        |> Enum.reject(fn {key, _} -> key == @target_header end)

      {:ok, %{host: host, headers: headers}}
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
