defmodule ProxyCat.DataStore.Adapter do
  @moduledoc """
  DataStore adapter behaviour.
  """
  @type options :: Keyword.t()

  @callback init(options()) :: options()
  @callback write_all(map(), options()) :: :ok | {:error, any()}
  @callback read_all(map(), options()) :: {:ok, any()} | {:error, any()}
  @callback delete_all([atom()], options()) :: :ok | {:error, any()}
end
