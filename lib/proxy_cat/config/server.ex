defmodule ProxyCat.Config.Server do
  use Agent

  @default_name __MODULE__

  def start_link(args) do
    Agent.start_link(&init/0, name: Keyword.get(args, :name, @default_name))
  end

  def config do
    Agent.get(@default_name, & &1)
  end

  def reload do
    Agent.stop(@default_name)
  end

  defp init do
    {:ok, config} = ProxyCat.Config.read_yaml()
    config
  end
end
