defmodule ProxyCat.Proxy.AuthServer.Handler.Jwt do
  @behaviour ProxyCat.Proxy.AuthServer.Handler

  require Logger

  alias ProxyCat.Proxy.AuthServer.Handler.Default, as: DefaultHandler

  @impl ProxyCat.Proxy.AuthServer.Handler
  def init(%ProxyCat.Config.AuthSpec.Jwt{
        client_id: client_id,
        access_token: access_token,
        refresh_token: refresh_token,
        refresh_url: refresh_url
      }) do
    send(self(), :check_expiration)

    put_tokens(
      %{
        refresh_url: refresh_url,
        client_id: client_id
      },
      access_token,
      refresh_token
    )
  end

  def extract_token_details(token) do
    with {:ok, %{"exp" => exp, "iat" => iat, "sub" => sub}} <- Joken.peek_claims(token) do
      {:ok,
       %{
         sub: sub,
         expires_at: DateTime.from_unix!(exp),
         inserted_at: DateTime.from_unix!(iat)
       }}
    end
  end

  @refresh_treshold_seconds div(:timer.minutes(5), :timer.seconds(1))
  @check_expiration_timer :timer.minutes(2)
  @impl ProxyCat.Proxy.AuthServer.Handler
  def handle_info(
        :check_expiration,
        %{
          expires_at: %DateTime{} = expires_at
        } = state
      ) do
    if DateTime.diff(expires_at, DateTime.utc_now()) < @refresh_treshold_seconds do
      attempt_refresh(state)
    else
      schedule_expiration_check()
      state
    end
  end

  def handle_info(_message, state) do
    state
  end

  defp attempt_refresh(
         %{client_id: client_id, refresh_token: refresh_token, refresh_url: refresh_url} = state
       ) do
    body = %{
      refresh_token: refresh_token,
      grant_type: "refresh_token",
      client_id: client_id
    }

    with {:ok,
          %Req.Response{
            status: 200,
            body: %{"access_token" => access_token, "refresh_token" => refresh_token}
          }} <- request(refresh_url, body) do
      schedule_expiration_check()
      put_tokens(state, access_token, refresh_token)
    else
      {_, error} ->
        Logger.error("[#{inspect(__MODULE__)}] [#{state.__key__}] #{inspect(error)}")
        state
    end
  end

  defp put_tokens(state, access_token, refresh_token) do
    token_details =
      case extract_token_details(access_token) do
        {:ok, details} -> details
        _ -> %{}
      end

    state
    |> Map.merge(%{
      access_token: access_token,
      refresh_token: refresh_token
    })
    |> Map.merge(token_details)
  end

  defp request(url, body) do
    {req, resp} = Req.run(method: :post, url: url, json: body)
    Logger.debug("[#{inspect(__MODULE__)}] [#{url}] #{inspect(req)}")
    {:ok, resp}
  end

  defp schedule_expiration_check() do
    Process.send_after(self(), :check_expiration, @check_expiration_timer)
  end

  @impl ProxyCat.Proxy.AuthServer.Handler
  def store(state, key, value), do: DefaultHandler.store(state, key, value)

  @impl ProxyCat.Proxy.AuthServer.Handler
  def retrieve(state, key), do: DefaultHandler.retrieve(state, key)
end
