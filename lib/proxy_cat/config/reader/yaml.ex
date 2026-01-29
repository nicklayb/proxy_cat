defmodule ProxyCat.Config.Reader.Yaml do
  @moduledoc """
  Yaml config file reader
  """
  @behaviour ProxyCat.Config.Reader

  @impl ProxyCat.Config.Reader
  def read(file_path) do
    YamlElixir.read_from_file(file_path)
  end
end
