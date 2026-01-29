defmodule ProxyCat.Proxy.AuthServer.State do
  @moduledoc """
  States for auth server
  """
  alias ProxyCat.Config.AuthSpec
  alias ProxyCat.Proxy.AuthServer.State

  defstruct [:handler, :auth_spec, :key, state: %{}]

  @type internal_state :: map()
  @type t :: %State{
          state: internal_state(),
          handler: module(),
          auth_spec: AuthSpec.t(),
          key: atom()
        }

  @doc """
  Stores a new value in the internal storage

  ## Examples

      iex> alias ProxyCat.Config.AuthSpec.Jwt
      iex> alias ProxyCat.Proxy.AuthServer.Handler.Default
      iex> alias ProxyCat.Proxy.AuthServer.State
      iex> State.store(%State{handler: Default, auth_spec: %Jwt{}, key: :my_app}, :some_key, "Value")
      %State{handler: Default, auth_spec: %Jwt{}, key: :my_app, state: %{some_key: "Value"}}
  """
  @spec store(t(), atom(), any()) :: t()
  def store(%State{handler: handler} = state, key, value) do
    map_state(state, &handler.store(&1, key, value))
  end

  @doc """
  Gets multiple keys from the internal store (or `:all` for everything)

  ## Examples

      iex> alias ProxyCat.Config.AuthSpec.Jwt
      iex> alias ProxyCat.Proxy.AuthServer.Handler.Default
      iex> alias ProxyCat.Proxy.AuthServer.State
      iex> state = State.store(%State{handler: Default, auth_spec: %Jwt{}, key: :my_app}, :some_key, "Value")
      iex> state = State.store(state, :other, "Thing")
      iex> State.get_keys(state, [:other])
      %{other: "Thing"}

      iex> alias ProxyCat.Config.AuthSpec.Jwt
      iex> alias ProxyCat.Proxy.AuthServer.Handler.Default
      iex> alias ProxyCat.Proxy.AuthServer.State
      iex> state = State.store(%State{handler: Default, auth_spec: %Jwt{}, key: :my_app}, :some_key, "Value")
      iex> state = State.store(state, :other, "Thing")
      iex> State.get_keys(state, :all)
      %{other: "Thing", some_key: "Value"}
  """
  @spec get_keys(t(), [atom()] | :all) :: map()
  def get_keys(%State{state: state, handler: handler}, keys) when is_list(keys) do
    Enum.reduce(keys, %{}, &Map.put(&2, &1, handler.retrieve(state, &1)))
  end

  def get_keys(%State{state: state}, :all) do
    state
  end

  @doc """
  Gets a value from the internal store

  ## Examples

      iex> alias ProxyCat.Config.AuthSpec.Jwt
      iex> alias ProxyCat.Proxy.AuthServer.Handler.Default
      iex> alias ProxyCat.Proxy.AuthServer.State
      iex> state = State.store(%State{handler: Default, auth_spec: %Jwt{}, key: :my_app}, :some_key, "Value")
      iex> State.get_key(state, :some_key)
      "Value"
  """
  @spec get_key(t(), atom()) :: any()
  def get_key(%State{state: state}, key), do: Map.get(state, key)

  defp map_state(%State{state: internal_state} = state, function) do
    %State{state | state: function.(internal_state)}
  end

  @doc """
  Puts the internal state inferring the key.

  ## Examples

      iex> alias ProxyCat.Config.AuthSpec.Jwt
      iex> alias ProxyCat.Proxy.AuthServer.Handler.Default
      iex> alias ProxyCat.Proxy.AuthServer.State
      iex> State.put_state(%State{handler: Default, auth_spec: %Jwt{}, key: :my_app}, %{key: "value"})
      %State{handler: Default, auth_spec: %Jwt{}, key: :my_app, state: %{__key__: :my_app, key: "value"}}
  """
  @spec put_state(t(), internal_state()) :: t()
  def put_state(%State{} = state, inner_state) do
    %State{state | state: Map.put(inner_state, :__key__, state.key)}
  end
end
