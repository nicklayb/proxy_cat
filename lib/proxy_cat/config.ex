defmodule ProxyCat.Config do
  @moduledoc """
  Module holding the proxy configuration file. It also defines
  the interface to follow to work with configurations.
  """
  alias ProxyCat.Config

  @callback decode(map()) :: struct()

  defdelegate config(), to: ProxyCat.Config.Server
  defdelegate reload(), to: ProxyCat.Config.Server

  defdelegate auth(config, key), to: ProxyCat.Config.Interface
  defdelegate stateful_proxies(config), to: ProxyCat.Config.Interface

  defdelegate update_headers(config, key, request_or_response, headers),
    to: ProxyCat.Config.Interface

  defdelegate host(config, key), to: ProxyCat.Config.Interface
  defdelegate proxy_exists?(config, key), to: ProxyCat.Config.Interface
  defdelegate current(), to: ProxyCat.Config.Server, as: :config

  @versions %{
    1 => Config.V1.Config
  }

  @type t :: Config.V1.Config.t()

  @doc "Reads configured yaml file into proper structure"
  @spec read_yaml() :: {:ok, t()} | {:error, any()}
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
