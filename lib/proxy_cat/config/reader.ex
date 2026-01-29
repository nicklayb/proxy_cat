defmodule ProxyCat.Config.Reader do
  @callback read(Path.t()) :: {:ok, map()} | {:error, any()}

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
