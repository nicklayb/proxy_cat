defmodule ProxyCat.Config.Server do
  @moduledoc """
  Server that holds the configuration in place. This has to 
  be started first in the supervision so that we can reload it
  and restart the entire tree to update.
  """
  use GenServer

  require Logger

  @default_name __MODULE__

  @type init_args :: [{:name, atom()}]

  @doc "Starts the server"
  @spec start_link(init_args()) :: Agent.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, [], name: Keyword.get(args, :name, @default_name))
  end

  @impl GenServer
  def init(_init_args) do
    state =
      %{}
      |> load_config()
      |> init_file_system_watcher()

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:config, _reply_to, %{config: config} = state) do
    {:reply, config, state}
  end

  @impl GenServer
  def handle_cast(:reload, state) do
    {:stop, :normal, state}
  end

  @expected_events ~w(modified closed)a
  @impl GenServer
  def handle_info(
        {:file_event, watcher_pid, {file_location, events}},
        %{watcher_pid: watcher_pid, file_location: file_location} = state
      ) do
    if Enum.all?(@expected_events, fn event -> event in events end) do
      Logger.info("[#{inspect(__MODULE__)}] [hot reload] restarting...")
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @doc "Returns current config"
  @spec config() :: ProxyCat.Config.t()
  def config do
    GenServer.call(@default_name, :config)
  end

  @doc "Retarts the server cascading to restart the whole tree"
  @spec reload() :: :ok
  def reload do
    GenServer.cast(@default_name, :reload)
  end

  defp load_config(state) do
    {:ok, config} = ProxyCat.Config.read()
    file_location = ProxyCat.Config.file_location()
    Map.merge(state, %{config: config, file_location: file_location})
  end

  defp init_file_system_watcher(%{file_location: file_location} = state) do
    pid =
      with :ok <- hot_reload_enabled(),
           {:ok, watcher_pid} <- FileSystem.start_link(dirs: [file_location]) do
        FileSystem.subscribe(watcher_pid)
        Logger.info("[#{inspect(__MODULE__)}] [hot reload] enabled")
        watcher_pid
      else
        _ -> nil
      end

    Map.put(state, :watcher_pid, pid)
  end

  defp hot_reload_enabled do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:hot_reload_enabled?)
    |> then(fn
      true -> :ok
      false -> :ingore
    end)
  end
end
