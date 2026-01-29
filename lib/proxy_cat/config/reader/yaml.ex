defmodule ProxyCat.Config.Reader.Yaml do
  @behaviour ProxyCat.Config.Reader

  @impl ProxyCat.Config.Reader
  def read(file_path) do
    YamlElixir.read_from_file(file_path)
  end
end
