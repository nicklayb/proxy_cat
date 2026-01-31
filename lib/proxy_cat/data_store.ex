defmodule ProxyCat.DataStore do
  @moduledoc """
  Persistent data store
  """
  alias ProxyCat.DataStore.Adapter

  @doc """
  Intializes options for the data store. All the other functions are expecting
  the return of this function in order to work properly as datastores might
  initialize some of the options.
  """
  @spec init(atom(), Adapter.options()) :: {:ok, Adapter.options()} | {:error, any()}
  def init(key, options) do
    {adapter, adapter_options} = adapter()

    adapter_options
    |> Keyword.merge(options)
    |> then(&adapter.init(key, &1))
  end

  @doc "Reads all entries (with optional defaults) from the configured data store"
  @spec read_all(map() | [atom()], Adapter.options()) :: {:ok, map()} | {:error, any()}
  def read_all(keys_with_defaults, options) when is_map(keys_with_defaults) do
    {adapter, _adapter_options} = adapter()
    adapter.read_all(keys_with_defaults, options)
  end

  def read_all(keys, options) when is_list(keys) do
    keys
    |> Map.new(&{&1, nil})
    |> read_all(options)
  end

  @doc "Deletes all entries from the configured data store"
  @spec delete_all([atom()], Adapter.options()) :: :ok | {:error, any()}
  def delete_all(keys, options) do
    {adapter, _adapter_options} = adapter()
    adapter.delete_all(keys, options)
  end

  @doc "Writes all values to the configured data store"
  @spec write_all(map(), Adapter.options()) :: :ok | {:error, any()}
  def write_all(keys_with_values, options) do
    {adapter, _adapter_options} = adapter()
    adapter.write_all(keys_with_values, options)
  end

  defp adapter do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> then(fn config ->
      adapter = Keyword.fetch!(config, :adapter)
      adapter_options = Keyword.fetch!(config, :adapter_options)
      {adapter, adapter_options}
    end)
  end
end
