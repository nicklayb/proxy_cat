defmodule ProxyCat.Proxy.AuthServer do
  @moduledoc """
  Server that holds Auth state. The kept state depends on the 
  AuthSpec provided and will invoke the appropriate `AuthServer.Handler`
  implementation to build the internal state.

  This server responds directly do `GenServer.cast/2` and 
  `GenServer.call/2` but forwards any other standard Erlang
  message down the the Handler. This allows for auto refresh 
  mechanisms for instance.
  """
  use GenServer

  alias ProxyCat.Config.AuthSpec
  alias ProxyCat.Proxy.AuthServer.Handler
  alias ProxyCat.Proxy.AuthServer.State

  require Logger

  @type init_args() :: [
          {:key, atom()},
          {:auth_spec, AuthSpec.t()},
          {:name, atom()}
        ]

  @doc "Child spec for supervisor"
  @spec child_spec(init_args()) :: map()
  def child_spec(args) do
    %{
      id: Keyword.fetch!(args, :name),
      start: {__MODULE__, :start_link, [args]}
    }
  end

  @doc "Starts server"
  @spec start_link([init_args()]) :: GenServer.on_start()
  def start_link(args) do
    name = Keyword.fetch!(args, :name)
    key = Keyword.fetch!(args, :key)
    auth_spec = Keyword.fetch!(args, :auth_spec)
    GenServer.start_link(__MODULE__, [key: key, auth_spec: auth_spec], name: name)
  end

  @impl GenServer
  def init(args) do
    key = Keyword.fetch!(args, :key)
    auth_spec = Keyword.fetch!(args, :auth_spec)
    handler = Handler.handler(auth_spec)
    Logger.info("[#{inspect(__MODULE__)}] [#{key}] [#{inspect(handler)}] started")
    initial_state = handler.init(auth_spec, key)

    state =
      State.put_state(%State{key: key, handler: handler, auth_spec: auth_spec}, initial_state)

    {:ok, state}
  end

  @doc "Retrieves all values (or all if `:all` is provided)"
  @spec retrieve_all(atom(), [atom()]) :: map()
  def retrieve_all(proxy_key, keys) do
    call(proxy_key, {:get_all, keys})
  end

  @doc "Retrieves one value"
  @spec retrieve(atom(), atom()) :: any()
  def retrieve(proxy_key, key) do
    call(proxy_key, {:get, key})
  end

  @doc "Stores a value in the state"
  @spec store(atom(), atom(), any()) :: :ok
  def store(proxy_key, key, value) do
    cast(proxy_key, {:store, key, value})
  end

  @impl GenServer
  def handle_call({:get, key}, _reply_to, %State{} = state) do
    value = State.get_key(state, key)

    {:reply, value, state}
  end

  def handle_call({:get_all, keys}, _reply_to, %State{} = state) do
    values = State.get_keys(state, keys)

    {:reply, values, state}
  end

  @impl GenServer
  def handle_cast({:store, key, value}, %State{} = state) do
    state = State.store(state, key, value)

    {:noreply, state}
  end

  @impl GenServer
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

  @doc "Qualifies proxy to state server name"
  @spec qualify_name(atom()) :: atom()
  def qualify_name(key) when is_atom(key) do
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
    Module.concat(__MODULE__, key)
  end
end
