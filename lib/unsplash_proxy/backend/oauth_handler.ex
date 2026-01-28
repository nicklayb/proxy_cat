defmodule ProxyCat.Backend.OauthHandler do
  alias ProxyCat.Routing.AuthSpec.Oauth2
  require Logger
  def init(_), do: [config: ProxyCat.Routing.Server.config()]

  def call(%Plug.Conn{params: %{"key" => proxy_key}} = conn, options) do
    config = Keyword.fetch!(options, :config)
    atom_key = String.to_existing_atom(proxy_key)

    code =
      conn
      |> Plug.Conn.fetch_query_params([])
      |> Map.fetch!(:params)
      |> Map.fetch("code")

    with {:ok, code} <- code,
         {:ok, %Oauth2{} = oauth} <- ProxyCat.Routing.Interface.auth(config, atom_key),
         {:ok, %Req.Response{}} <- fetch_access_token(oauth, code, atom_key) do
      Logger.info("[#{inspect(__MODULE__)}] [#{proxy_key}] [Success]")
      Plug.Conn.send_resp(conn, 200, "OK")
    else
      :error ->
        Logger.error("[#{inspect(__MODULE__)}] [#{proxy_key}] Missing code param")
        Plug.Conn.send_resp(conn, 500, "Got error: Missing code param")

      {:error, error} ->
        Logger.error("[#{inspect(__MODULE__)}] [#{proxy_key}] #{inspect(error)}")
        Plug.Conn.send_resp(conn, 500, "Got error: #{inspect(error)}")
    end
  end

  defp fetch_access_token(%Oauth2{} = oauth, code, key) do
    {uri, params} =
      Oauth2.token_call_spec(oauth, code, "http://localhost:4004/oauth/callback/#{key}")

    url = URI.to_string(uri)

    with {:ok, %Req.Response{status: 200, body: body} = response} <-
           Req.post(url: url, form: params) do
      persist_tokens(oauth, key, body)
      {:ok, response}
    else
      {:ok, response} -> {:error, response}
      error -> error
    end
  end

  @keys ~w(access_token expires_in scope token_type)a

  defp persist_tokens(%Oauth2{refresh_token: refresh_token}, key, body) do
    Enum.each(@keys, fn current_key ->
      body
      |> Map.get(to_string(current_key))
      |> then(&ProxyCat.Proxy.StateServer.store(key, current_key, &1))
    end)

    if refresh_token do
      body
      |> Map.get("refresh_token")
      |> then(&ProxyCat.Proxy.StateServer.store(key, :refresh_token, &1))
    end
  end
end
