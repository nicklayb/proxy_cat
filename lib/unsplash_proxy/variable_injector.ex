defmodule ProxyCat.VariableInjector do
  @variable_regex ~r/\%([A-Z0-9_-]+)\%/
  def inject(string, variable_getter \\ &System.get_env/1)

  def inject(list, variable_getter) when is_list(list) do
    Enum.map(list, &inject(&1, variable_getter))
  end

  def inject(map, variable_getter) when is_map(map) do
    Map.new(map, fn {key, value} -> {key, variable_getter.(value)} end)
  end

  def inject(string, variable_getter) when is_binary(string) do
    @variable_regex
    |> Regex.scan(string)
    |> Enum.reduce(string, fn [raw, captured], acc ->
      value = variable_getter.(captured) || ""
      String.replace(acc, raw, value)
    end)
  end

  def inject(other, _), do: other
end
