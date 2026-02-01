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
  defdelegate cache(config, key), to: ProxyCat.Config.Interface

  defdelegate current(), to: ProxyCat.Config.Server, as: :config

  @versions %{
    1 => Config.V1.Config
  }

  @type t :: Config.V1.Config.t()

  @doc "Reads configured file into proper structure"
  @spec read() :: {:ok, t()} | {:error, any()}
  def read do
    with {:ok, %{"version" => version} = body} <- Config.Reader.read(file_location()) do
      {:ok, decode_by_version(version, body)}
    end
  end

  defp decode_by_version(version, body) do
    with {:ok, config} <- Box.Map.fetch(@versions, version, :unsupported_version) do
      config.decode(body)
    end
  end

  @doc "Returns the configured file location"
  @spec file_location() :: Path.t()
  def file_location do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:file)
  end
end
