defmodule ProxyCat.Proxy.AuthServer.Handler.Oauth do
  @moduledoc """
  Default handler that just stores things up and ignore
  any messages it receives.
  """
  @behaviour ProxyCat.Proxy.AuthServer.Handler

  alias ProxyCat.Config.AuthSpec.Oauth2
  alias ProxyCat.DataStore
  alias ProxyCat.Proxy.AuthServer.Handler

  require Logger

  @impl Handler
  def init(%Oauth2{} = oauth, key) do
    authorize_url = Oauth2.authorize_url(oauth, key)

    Logger.info("[#{inspect(__MODULE__)}] [authorize_url] #{authorize_url}")
    init_state(key)
  end

  defp init_state(key) do
    data_store_options =
      case DataStore.init(key, []) do
        {:ok, options} ->
          options

        error ->
          Logger.warning("[#{inspect(__MODULE__)}] [#{key}] [data_store_error] #{error}")
          nil
      end

    %{data_store_options: data_store_options, key: key}
    |> read_from_store()
    |> tap(&log_init/1)
  end

  defp log_init(%{key: key, access_token: access_token}) when is_binary(access_token) do
    Logger.info("[#{inspect(__MODULE__)}] [#{key}] loaded access token from data store")
  end

  defp log_init(_other) do
    :noop
  end

  @persisted_keys ~w(access_token expires_in scope token_type refresh_token)a
  defp read_from_store(%{data_store_options: data_store_options} = state) do
    case DataStore.read_all(@persisted_keys, data_store_options) do
      {:ok, result} ->
        Map.merge(state, result)

      _error ->
        state
    end
  end

  @impl Handler
  def handle_info(_message, state) do
    state
  end

  @impl Handler
  def store(%{data_store_options: data_store_options} = state, key, value)
      when key in @persisted_keys and not is_nil(value) do
    DataStore.write_all(%{key => value}, data_store_options)
    Handler.Default.store(state, key, value)
  end

  def store(state, key, value) do
    Handler.Default.store(state, key, value)
  end

  @impl Handler
  defdelegate retrieve(state, key), to: Handler.Default
end
