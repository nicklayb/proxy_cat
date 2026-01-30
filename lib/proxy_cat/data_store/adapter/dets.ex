defmodule ProxyCat.DataStore.Adapter.Dets do
  @behaviour ProxyCat.DataStore.Adapter

  @impl ProxyCat.DataStore.Adapter
  def init(options) do
    table_name = Keyword.fetch!(options, :table_name)
    file = Keyword.fetch!(options, :file)
    [table_name: table_name, file: String.to_charlist(file)]
  end

  @impl ProxyCat.DataStore.Adapter
  def read_all(keys_with_default, options) do
    result =
      with_table(options, fn table_name ->
        Enum.reduce(keys_with_default, %{}, fn {key, default}, acc ->
          value =
            case :dets.lookup(table_name, key) do
              [{^key, value}] -> value
              _ -> default
            end

          Map.put(acc, key, value)
        end)
      end)

    {:ok, result}
  end

  @impl ProxyCat.DataStore.Adapter
  def write_all(keys_with_value, options) do
    with_table(options, fn table_name ->
      Enum.each(keys_with_value, fn {key, value} ->
        :dets.insert(table_name, {key, value})
      end)
    end)
  end

  @impl ProxyCat.DataStore.Adapter
  def delete_all(keys, options) do
    with_table(options, fn table_name ->
      Enum.each(keys, &:dets.delete(table_name, &1))
    end)
  end

  defp with_table(options, function) do
    table_name = Keyword.fetch!(options, :table_name)
    file = Keyword.fetch!(options, :file)

    with {:ok, ^table_name} <- :dets.open_file(table_name, file: file) do
      result = function.(table_name)
      :dets.close(table_name)
      result
    end
  end
end
