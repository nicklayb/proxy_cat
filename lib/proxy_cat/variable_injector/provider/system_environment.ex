defmodule ProxyCat.VariableInjector.Provider.SystemEnvironment do
  @moduledoc """
  Provides system variable
  """
  @behaviour ProxyCat.VariableInjector.Provider

  @impl ProxyCat.VariableInjector.Provider
  def provide(key) do
    System.get_env(key)
  end
end
