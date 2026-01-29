defmodule ProxyCat.Config do
  alias ProxyCat.Config

  defdelegate config(), to: ProxyCat.Config.Server
  defdelegate reload(), to: ProxyCat.Config.Server

  @versions %{
    1 => Config.V1.Config
  }

  @type configuration :: Config.V1.Config.t()

  @doc "Reads configured yaml file into proper structure"
  @spec read_yaml() :: {:ok, configuration()} | {:error, any()}
  def read_yaml do
    with {:ok, %{"version" => version} = body} <- Config.Reader.read(file_location()) do
      {:ok, decode_by_version(version, body)}
    end
  end

  defp decode_by_version(version, body) do
    case Map.fetch(@versions, version) do
      :error -> {:error, :unsupported_version}
      {:ok, config} -> config.decode(body)
    end
  end

  defp file_location do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:config_yaml)
  end
end
