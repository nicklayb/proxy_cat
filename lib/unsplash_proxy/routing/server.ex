defmodule ProxyCat.Routing.Server do
  use Agent

  @default_name __MODULE__

  def start_link(args) do
    Agent.start_link(&init/0, name: Keyword.get(args, :name, @default_name))
  end

  def config(options \\ []) do
    if Keyword.get(options, :refresh, false) do
      Agent.get_and_update(@default_name, fn _ ->
        config = init()
        {config, config}
      end)
    else
      Agent.get(@default_name, & &1)
    end
  end

  def reload do
    Agent.update(@default_name, fn _ -> init() end)
  end

  defp init do
    {:ok, config} = ProxyCat.Routing.read_yaml()
    config
  end
end
