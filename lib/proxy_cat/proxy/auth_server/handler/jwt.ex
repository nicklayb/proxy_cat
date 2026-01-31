defmodule ProxyCat.Proxy.AuthServer.Handler.Jwt do
  @moduledoc """
  Handlers JWT auth spec. This handler will maintain the access token
  up to date by refreshing it a few minutes before expiration.

  The expiration is calculated by the internal JWT state.

  It doesn't do anything particular with the values it stores so
  it defers to the default handler.
  """
  @behaviour ProxyCat.Proxy.AuthServer.Handler

  alias ProxyCat.DataStore
  alias ProxyCat.Http
  alias ProxyCat.Proxy.AuthServer.Handler

  require Logger

  @impl Handler
  def init(
        %ProxyCat.Config.AuthSpec.Jwt{
          client_id: client_id,
          access_token: access_token,
          refresh_token: refresh_token,
          refresh_url: refresh_url
        },
        key
      ) do
    send(self(), :check_expiration)

    data_store_options =
      case DataStore.init(key, []) do
        {:ok, options} ->
          options

        error ->
          Logger.warning("[#{inspect(__MODULE__)}] [#{key}] [data_store_error] #{error}")
          nil
      end

    init_tokens(
      %{
        key: key,
        data_store_options: data_store_options,
        refresh_url: refresh_url,
        client_id: client_id
      },
      access_token,
      refresh_token
    )
  end

  @refresh_treshold_seconds div(:timer.minutes(5), :timer.seconds(1))
  @check_expiration_timer :timer.minutes(2)
  @impl Handler
  def handle_info(
        :check_expiration,
        %{
          expires_at: %DateTime{} = expires_at
        } = state
      ) do
    if DateTime.diff(expires_at, DateTime.utc_now()) < @refresh_treshold_seconds do
      attempt_refresh(state)
    else
      schedule_expiration_check(state)
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

    case request(refresh_url, body) do
      {:ok, _request,
       %Http.Response{
         body: %{"access_token" => access_token, "refresh_token" => refresh_token}
       }} ->
        state
        |> schedule_expiration_check()
        |> put_tokens(access_token, refresh_token)

      {_ok_or_error, _request, non_200_response} ->
        Logger.error("[#{inspect(__MODULE__)}] [#{state.__key__}] #{inspect(non_200_response)}")
        state
    end
  end

  @persisted_keys ~w(access_token refresh_token)a
  defp init_tokens(
         %{data_store_options: data_store_options} = initial_state,
         access_token,
         refresh_token
       ) do
    configured_tokens = %{access_token: access_token, refresh_token: refresh_token}

    with {:ok, tokens} <- require_persisted_keys(data_store_options),
         {:ok, payload} <- latest_token(tokens, configured_tokens) do
      Map.merge(initial_state, payload)
    else
      _error ->
        put_tokens(initial_state, access_token, refresh_token)
    end
  end

  defp require_persisted_keys(data_store_options) do
    case DataStore.read_all(@persisted_keys, data_store_options) do
      {:ok, %{access_token: access_token, refresh_token: refresh_token} = payload}
      when is_binary(access_token) and is_binary(refresh_token) ->
        {:ok, payload}

      _other ->
        {:error, :missing_keys}
    end
  end

  defp put_tokens(
         state,
         access_token,
         refresh_token
       ) do
    token_details =
      case extract_token_details(access_token) do
        {:ok, details} ->
          tokens = %{access_token: access_token, refresh_token: refresh_token}
          persist_tokens(state, tokens)
          Map.merge(details, tokens)

        _error ->
          clear_tokens(state)
          %{access_token: nil, refresh_token: nil}
      end

    Map.merge(state, token_details)
  end

  defp persist_tokens(%{data_store_options: data_store_options}, token_details) do
    token_details
    |> Map.take(@persisted_keys)
    |> DataStore.write_all(data_store_options)
  end

  defp clear_tokens(%{data_store_options: data_store_options}) do
    DataStore.delete_all(@persisted_keys, data_store_options)
  end

  defp extract_token_details(nil), do: {:error, :missing_token}

  defp extract_token_details(token) do
    with {:ok, %{"exp" => exp, "iat" => iat}} <- Joken.peek_claims(token) do
      {:ok,
       %{
         expires_at: DateTime.from_unix!(exp),
         inserted_at: DateTime.from_unix!(iat)
       }}
    end
  end

  defp latest_token(
         %{access_token: left_token} = left_payload,
         %{access_token: right_token} = right_payload
       ) do
    with {:ok, %{inserted_at: left_inserted_at} = left_claims} <-
           extract_token_details(left_token),
         {:ok, %{inserted_at: right_inserted_at} = right_claims} <-
           extract_token_details(right_token) do
      payload =
        if DateTime.compare(left_inserted_at, right_inserted_at) == :gt do
          Map.merge(left_claims, left_payload)
        else
          Map.merge(right_claims, right_payload)
        end

      {:ok, payload}
    end
  end

  defp request(url, body) do
    [method: :post, url: url, json: body]
    |> Http.request_200()
    |> tap(fn {_ok_or_error, request, _error_or_response} ->
      Logger.debug("[#{inspect(__MODULE__)}] [#{url}] #{inspect(request)}")
    end)
  end

  defp schedule_expiration_check(state) do
    timer = Process.send_after(self(), :check_expiration, @check_expiration_timer)
    Map.put(state, :expiration_timer, timer)
  end

  @impl Handler
  def store(state, key, value), do: Handler.Default.store(state, key, value)

  @impl Handler
  def retrieve(state, key), do: Handler.Default.retrieve(state, key)
end
