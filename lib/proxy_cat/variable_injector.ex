defmodule ProxyCat.VariableInjector do
  @moduledoc """
  Responsible for variable injection into terms. This is used to
  replace `%SOME_CONFIG%` in the configuration files to their
  system variable values or any other variable store.
  """
  @variable_regex ~r/\%([A-Z0-9_-]+)\%/

  @type variable_getter :: (String.t() -> String.t())

  @doc """
  Injects variables from variable getter into string

  ## Examples

      iex> ProxyCat.VariableInjector.inject("Hello %NAME%", &Map.get(%{"NAME" => "John"}, &1))
      "Hello John"
  """
  @spec inject(term(), variable_getter()) :: term()
  def inject(string, variable_getter \\ &System.get_env/1)

  def inject(list, variable_getter) when is_list(list) do
    Enum.map(list, &inject(&1, variable_getter))
  end

  def inject(map, variable_getter) when is_map(map) do
    Map.new(map, fn {key, value} -> {key, inject(value, variable_getter)} end)
  end

  def inject(string, variable_getter) when is_binary(string) do
    @variable_regex
    |> Regex.scan(string)
    |> Enum.reduce(string, fn [raw, captured], acc ->
      value = variable_getter.(captured) || ""
      String.replace(acc, raw, value)
    end)
  end

  def inject(other, _getter), do: other
end
