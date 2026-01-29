defmodule ProxyCat.Config.Reader do
  @moduledoc """
  Reader protocol to read config files. The files are expected to
  output a map which will later be converted to proper structs.
  """
  @callback read(Path.t()) :: {:ok, map()} | {:error, any()}

  @doc "Reads config file using configured adapter"
  @spec read(Path.t()) :: {:ok, map()} | {:error, any()}
  def read(file_path) do
    adapter = adapter()

    adapter.read(file_path)
  end

  defp adapter do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:adapter)
  end
end
