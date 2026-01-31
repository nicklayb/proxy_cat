defmodule ProxyCat.Proxy.Handler do
  @moduledoc """
  Handles proxy requests inferring configured headers
  and authentication tokens if any.

  Process goes as follow:

  1. Receive a request externally
  2. Uses the `X-ProxyCat-Target` header value to find the target proxy
  3. Updates request headers according to proxy's configuration
  4. Infer authentication if any
  5. Call the proxied service with the headers, same body and same path
  6. Returns the proxied service's response with updated headers if any.
  """
  @behaviour Plug

  alias ProxyCat.Cache
  alias ProxyCat.Config.AuthSpec.Jwt
  alias ProxyCat.Config.AuthSpec.Oauth2
  alias ProxyCat.Config.CacheSpec
  alias ProxyCat.Http
  alias ProxyCat.Proxy.StateServer

  require Logger

  @impl Plug
  def init(_args) do
    []
  end

  @impl Plug
  def call(%Plug.Conn{} = conn, _options) do
    config = ProxyCat.Config.current()

    with {:ok, %{host: host, target: target, auth: auth, headers: headers}} <-
           fetch_proxy_config(config, conn),
         {:ok, %Plug.Conn{} = conn} <- call_target(conn, config, target, host, headers, auth) do
      conn
    else
      error ->
        handle_error(conn, error)
    end
  end

  defp handle_error(conn, {:error, %Http.Request{}, %Http.Response{status: status, body: body}}) do
    Plug.Conn.send_resp(conn, status, body)
  end

  defp handle_error(conn, {:error, error}) do
    Logger.error("[#{inspect(__MODULE__)}] [error] #{inspect(error)}")
    Plug.Conn.send_resp(conn, 500, "Bad request")
  end

  defp handle_error(conn, error) do
    handle_error(conn, {:error, error})
  end

  defp call_target(%Plug.Conn{} = conn, config, target, %URI{} = host, headers, auth) do
    method = to_atom_method(conn.method)
    uri = build_uri(conn, host)
    all_headers = build_headers(uri, headers, target, auth)
    cache_spec = ProxyCat.Config.cache(config, target)

    with {:ok, body, conn} <- Plug.Conn.read_body(conn),
         {:ok, _request, response} <- request(method, uri, all_headers, body, cache_spec) do
      {:ok, respond_from_response(conn, uri, config, target, response)}
    end
  end

  defp build_uri(%Plug.Conn{} = conn, %URI{} = host) do
    path =
      case conn.path_info do
        [] -> ""
        parts -> Path.join(parts)
      end

    %URI{host | path: "/" <> path, query: conn.query_string}
  end

  defp build_headers(%URI{} = uri, headers, target, auth) do
    auth_headers = auth_headers(target, auth)

    (headers ++ auth_headers)
    |> Enum.reject(fn {key, _value} -> String.downcase(key) == "host" end)
    |> then(&[{"host", uri.host} | &1])
  end

  defp auth_headers(target, %Oauth2{}) do
    %{access_token: access_token, token_type: token_type} =
      StateServer.retrieve_all(target, [:access_token, :token_type])

    [auth_header("#{token_type} #{access_token}")]
  end

  defp auth_headers(target, %Jwt{}) do
    access_token =
      StateServer.retrieve(target, :access_token)

    [auth_header("Bearer #{access_token}")]
  end

  defp auth_headers(_target, nil), do: []

  defp auth_header(string), do: {"Authorization", string}

  defp request(method, uri, headers, body, cache_spec) do
    ttl = cache_ttl(cache_spec)

    uri
    |> cache_key()
    |> Cache.cached([cache_match: &should_cache?/1, ttl: ttl], fn ->
      Logger.info("[#{inspect(__MODULE__)}] [#{method}] [#{URI.to_string(uri)}]")

      Http.request_200(
        method: method,
        url: uri,
        headers: headers,
        decode_body: false,
        body: body
      )
    end)
  end

  defp cache_ttl(%CacheSpec{ttl: ttl}), do: ttl
  defp cache_ttl(_missing_cache_spec), do: 0

  defp should_cache?({:ok, _request, %Http.Response{}}), do: true

  defp should_cache?(_non_200_response), do: false

  defp cache_key(%URI{path: path, query: query}) do
    :sha256
    |> :crypto.hash("#{path}?#{query}")
    |> Base.encode16()
    |> String.downcase()
  end

  defp respond_from_response(conn, %URI{} = uri, config, target, %Http.Response{} = response) do
    Logger.debug("[#{inspect(__MODULE__)}] [#{response.status}] [#{uri.path}]")

    config
    |> ProxyCat.Config.update_headers(target, :response, response.headers)
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
         {:ok, true} <- proxy_exists?(config, target),
         {:ok, host} <- ProxyCat.Config.host(config, target) do
      headers =
        config
        |> ProxyCat.Config.update_headers(target, :request, conn.req_headers)
        |> Enum.reject(fn {key, _value} -> key == @target_header end)

      auth = ProxyCat.Config.auth(config, target)

      {:ok, %{target: target, host: host, headers: headers, auth: auth}}
    end
  end

  defp proxy_exists?(config, target) do
    if ProxyCat.Config.proxy_exists?(config, target) do
      {:ok, true}
    else
      {:error, :not_found}
    end
  end

  defp get_target_header(%Plug.Conn{} = conn) do
    case Plug.Conn.get_req_header(conn, @target_header) do
      [value | _rest] ->
        {:ok, String.to_existing_atom(value)}

      _empty ->
        {:error, :not_found}
    end
  rescue
    _error ->
      {:error, :invalid_target}
  end
end
