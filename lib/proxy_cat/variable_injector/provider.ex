defmodule ProxyCat.VariableInjector.Provider do
  @moduledoc """
  Provider behaviour for variable injection
  """

  @type t :: ProxyCat.VariableInjector.Provider.SystemVariable

  @callback provide(String.t()) :: String.t() | nil
end
