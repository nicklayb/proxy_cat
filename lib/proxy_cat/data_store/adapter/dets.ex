defmodule ProxyCat.DataStore.Adapter.Dets do
  @moduledoc """
  Data store adapter that uses Erlang's `:dets` module.
  """
  @behaviour ProxyCat.DataStore.Adapter

  require Logger

  @impl ProxyCat.DataStore.Adapter
  def init(table_name, options) do
    file =
      options
      |> Keyword.fetch!(:directory)
      |> Path.join("#{table_name}.dat")

    options = [
      table_name: table_name,
      file: String.to_charlist(file),
      write_nil?: Keyword.get(options, :write_nil?, false)
    ]

    with :ok <- with_table(options, fn _table_name -> :ok end) do
      {:ok, options}
    end
  end

  @impl ProxyCat.DataStore.Adapter
  def read_all(keys_with_default, options) do
    result =
      with_table(options, fn table_name ->
        Logger.debug(
          "[#{inspect(__MODULE__)}] [#{table_name}] [#{inspect(Map.keys(keys_with_default))}] read"
        )

        lookup_values(table_name, keys_with_default, options)
      end)

    {:ok, result}
  end

  defp lookup_values(table_name, keys_with_default, options) do
    write_nil? = Keyword.fetch!(options, :write_nil?)

    Enum.reduce(keys_with_default, %{}, fn {key, default}, acc ->
      case {:dets.lookup(table_name, key), write_nil?} do
        {[{_key, nil}], false} ->
          acc

        {[{^key, value}], _write_nil?} ->
          Map.put(acc, key, value)

        _non_matching ->
          Map.put(acc, key, default)
      end
    end)
  end

  @impl ProxyCat.DataStore.Adapter
  def write_all(keys_with_value, options) do
    with_table(options, fn table_name ->
      entries = clean_entries(keys_with_value, options)

      Logger.info(
        "[#{inspect(__MODULE__)}] [#{table_name}] [#{inspect(Map.keys(entries))}] written"
      )

      Enum.each(entries, fn {key, value} ->
        :dets.insert(table_name, {key, value})
      end)
    end)
  end

  defp clean_entries(entries, options) do
    if Keyword.fetch!(options, :write_nil?) do
      entries
    else
      Box.Map.filter(entries, fn {_key, value} -> not is_nil(value) end)
    end
  end

  @impl ProxyCat.DataStore.Adapter
  def delete_all(keys, options) do
    with_table(options, fn table_name ->
      Logger.info("[#{inspect(__MODULE__)}] [#{table_name}] [#{inspect(keys)}] deleted")
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
