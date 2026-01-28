defmodule ProxyCat.Proxy.StateServer do
  use Supervisor

  defmodule StateAgent do
    use Agent

    require Logger

    def start_link(options) do
      name = Keyword.fetch!(options, :name)
      key = Keyword.fetch!(options, :key)
      type = Keyword.fetch!(options, :type)

      Agent.start_link(
        fn ->
          Logger.info("[#{inspect(__MODULE__)}] [#{key}] started")
          %{key: key, type: type, state: %{}}
        end,
        name: name
      )
    end

    def store(name, key, value) do
      Agent.update(name, fn state -> Map.update!(state, :state, &Map.put(&1, key, value)) end)
    end

    def retrieve(name, key) do
      Agent.get(name, fn %{state: state} -> Map.get(state, key) end)
    end

    def retrieve_all(name, keys) do
      Agent.get(name, fn %{state: state} ->
        case keys do
          :all ->
            state

          keys when is_list(keys) ->
            Map.new(keys, &{&1, Map.get(state, &1)})
        end
      end)
    end
  end

  @name __MODULE__
  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @impl Supervisor
  def init(_init_arg) do
    children = children(ProxyCat.Routing.Server.config())
    Supervisor.init(children, strategy: :one_for_one)
  end

  def store(proxy_key, key, value) do
    proxy_key
    |> state_name()
    |> StateAgent.store(key, value)
  end

  def retrieve(proxy_key, key) do
    proxy_key
    |> state_name()
    |> StateAgent.retrieve(key)
  end

  def retrieve_all(proxy_key, keys) do
    proxy_key
    |> state_name()
    |> StateAgent.retrieve_all(keys)
  end

  def clear(proxy_key, key) do
    store(proxy_key, key, nil)
  end

  defp children(config) do
    config
    |> ProxyCat.Routing.Interface.stateful_proxies()
    |> Enum.map(fn {type, key} ->
      full_name = state_name(key)

      {StateAgent, [key: key, type: type, name: full_name]}
    end)
  end

  defp state_name(key), do: Module.concat([__MODULE__, key])
end
