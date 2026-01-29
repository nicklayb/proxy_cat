defmodule ProxyCat.Config.Server do
  @moduledoc """
  Server that holds the configuration in place. This has to 
  be started first in the supervision so that we can reload it
  and restart the entire tree to update.
  """
  use Agent

  @default_name __MODULE__

  @type init_args :: [{:name, atom()}]

  @doc "Starts the server"
  @spec start_link(init_args()) :: Agent.on_start()
  def start_link(args) do
    Agent.start_link(&init/0, name: Keyword.get(args, :name, @default_name))
  end

  @doc "Returns current config"
  @spec config() :: ProxyCat.Config.t()
  def config do
    Agent.get(@default_name, & &1)
  end

  @doc "Retarts the server cascading to restart the whole tree"
  @spec reload() :: :ok
  def reload do
    Agent.stop(@default_name)
  end

  defp init do
    {:ok, config} = ProxyCat.Config.read_yaml()
    config
  end
end
