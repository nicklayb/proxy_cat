defmodule ProxyCat.Backend.OauthHandler do
  @moduledoc """
  OAuth Request handlers. Since OAuth2 configurations uses
  a callback URL to return the authorized code, this module
  handles those requests and stores the returned token to
  the appropriate state servers.
  """

  @behaviour Plug
  alias ProxyCat.Config.AuthSpec.Oauth2
  alias ProxyCat.Proxy.StateServer
  require Logger

  @impl Plug
  def init(_args), do: []

  @impl Plug
  @doc """
  Handles callback requests. The callback endpoints expects a `:key`
  parameter that is used as the Proxy target to find the appropriate
  configuration.
  """
  def call(%Plug.Conn{params: %{"key" => proxy_key}} = conn, _options) do
    config = ProxyCat.Config.current()

    params =
      conn
      |> Plug.Conn.fetch_query_params([])
      |> Map.fetch!(:params)

    with {:ok, atom_key} <- convert_atom(proxy_key),
         {:ok, code} <- Map.fetch(params, "code"),
         {:ok, %Oauth2{} = oauth} <- fetch_auth(config, atom_key),
         {:ok, %Req.Response{}} <- fetch_access_token(oauth, code, atom_key) do
      Logger.info("[#{inspect(__MODULE__)}] [#{proxy_key}] [Success]")
      Plug.Conn.send_resp(conn, 200, "OK")
    else
      error ->
        handle_error(conn, proxy_key, error)
    end
  end

  defp handle_error(conn, proxy_key, :error) do
    Logger.error("[#{inspect(__MODULE__)}] [#{proxy_key}] Missing code param")
    Plug.Conn.send_resp(conn, 500, "Got error: Missing code param")
  end

  defp handle_error(conn, proxy_key, {:error, :no_such_proxy}) do
    Logger.error("[#{inspect(__MODULE__)}] [#{proxy_key}] :no_such_proxy")
    Plug.Conn.send_resp(conn, 404, "Not found")
  end

  defp handle_error(conn, proxy_key, {:error, error}) do
    Logger.error("[#{inspect(__MODULE__)}] [#{proxy_key}] #{inspect(error)}")
    Plug.Conn.send_resp(conn, 500, "Got error: #{inspect(error)}")
  end

  defp fetch_auth(config, atom_key) do
    case ProxyCat.Config.auth(config, atom_key) do
      %Oauth2{} = oauth -> {:ok, oauth}
      _other_auth -> {:error, :invalid_auth}
    end
  end

  defp convert_atom(proxy_key) do
    {:ok, String.to_existing_atom(proxy_key)}
  rescue
    _error -> {:error, :no_such_proxy}
  end

  defp fetch_access_token(%Oauth2{} = oauth, code, key) do
    {uri, params} =
      Oauth2.token_call_spec(oauth, code, key)

    url = URI.to_string(uri)

    case Req.post(url: url, form: params) do
      {:ok, %Req.Response{status: 200, body: body} = response} ->
        persist_tokens(oauth, key, body)
        {:ok, response}

      {:ok, response} ->
        {:error, response}

      error ->
        error
    end
  end

  @keys ~w(access_token expires_in scope token_type)a

  defp persist_tokens(%Oauth2{refresh_url: refresh_url}, key, body) do
    Enum.each(@keys, fn current_key ->
      body
      |> Map.get(to_string(current_key))
      |> then(&StateServer.store(key, current_key, &1))
    end)

    if match?(%URI{}, refresh_url) do
      body
      |> Map.get("refresh_token")
      |> then(&StateServer.store(key, :refresh_token, &1))
    end
  end
end
