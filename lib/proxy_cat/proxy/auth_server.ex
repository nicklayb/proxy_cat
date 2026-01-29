defmodule ProxyCat.Proxy.AuthServer do
  alias ProxyCat.Proxy.AuthServer.Handler
  alias ProxyCat.Config.AuthSpec
  use GenServer
  require Logger

  defmodule State do
    defstruct [:state, :handler, :auth_spec, :key]

    def store(%State{handler: handler} = state, key, value) do
      map_state(state, &handler.store(&1, key, value))
    end

    def get_keys(%State{state: state, handler: handler}, keys) when is_list(keys) do
      Enum.reduce(keys, %{}, &Map.put(&2, &1, handler.retrieve(state, &1)))
    end

    def get_keys(%State{state: state}, :all) do
      state
    end

    def get_key(%State{state: state}, key), do: Map.get(state, key)

    defp map_state(%State{state: internal_state} = state, function) do
      %State{state | state: function.(internal_state)}
    end

    def put_state(%State{} = state, inner_state) do
      %State{state | state: Map.put(inner_state, :__key__, state.key)}
    end
  end

  def child_spec(args) do
    %{
      id: Keyword.fetch!(args, :name),
      start: {__MODULE__, :start_link, [args]}
    }
  end

  def start_link(args) do
    name = Keyword.fetch!(args, :name)
    key = Keyword.fetch!(args, :key)
    auth_spec = Keyword.fetch!(args, :auth_spec)
    GenServer.start_link(__MODULE__, [key: key, auth_spec: auth_spec], name: name)
  end

  def init(args) do
    key = Keyword.fetch!(args, :key)
    auth_spec = Keyword.fetch!(args, :auth_spec)
    handler = handler(auth_spec)
    initial_state = handler.init(auth_spec)

    Logger.info("[#{inspect(__MODULE__)}] [#{key}] [#{inspect(auth_spec.__struct__)}] started")

    state =
      State.put_state(%State{key: key, handler: handler, auth_spec: auth_spec}, initial_state)

    {:ok, state}
  end

  defp handler(%AuthSpec.Jwt{}), do: Handler.Jwt

  defp handler(%AuthSpec.Oauth2{}), do: Handler.Default

  def retrieve_all(proxy_key, keys) do
    call(proxy_key, {:get_all, keys})
  end

  def retrieve(proxy_key, key) do
    call(proxy_key, {:get, key})
  end

  def store(proxy_key, key, value) do
    cast(proxy_key, {:store, key, value})
  end

  def handle_call({:get, key}, _, %State{} = state) do
    value = State.get_key(state, key)

    {:reply, value, state}
  end

  def handle_call({:get_all, keys}, _, %State{} = state) do
    values = State.get_keys(state, keys)

    {:reply, values, state}
  end

  def handle_cast({:store, key, value}, %State{} = state) do
    state = State.store(state, key, value)

    {:noreply, state}
  end

  def handle_info(message, %State{handler: handler, state: internal_state} = state) do
    new_state = handler.handle_info(message, internal_state)

    {:noreply, State.put_state(state, new_state)}
  end

  defp cast(key, message) do
    key
    |> qualify_name()
    |> GenServer.cast(message)
  end

  defp call(key, message) do
    key
    |> qualify_name()
    |> GenServer.call(message)
  end

  def qualify_name(key) when is_atom(key) do
    Module.concat(__MODULE__, key)
  end
end
