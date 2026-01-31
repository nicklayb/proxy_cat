defmodule ProxyCat.Support.Fixtures do
  @moduledoc """
  Data structure fixture genrators
  """
  @base_path "./test/support/fixtures/"

  @doc "Generates a config file path"
  @spec config_file(non_neg_integer(), Path.t()) :: Path.t()
  def config_file(version, file_name) do
    Path.join([@base_path, "config", "v#{version}", file_name])
  end

  @doc "Generates a config file path asserting it exists"
  @spec config_file!(non_neg_integer(), Path.t()) :: Path.t()
  def config_file!(version, file_name) do
    version
    |> config_file(file_name)
    |> tap(fn file ->
      if not File.exists?(file), do: raise(ArgumentError, "File #{file} does not exists")
    end)
  end
end
