defmodule ProxyCat.Config.V1.Config do
  @moduledoc """
  Config version 1
  """
  @behaviour ProxyCat.Config

  use Starchoice.Decoder

  alias ProxyCat.Config.V1.Config

  defstruct proxies: %{}

  @type proxies :: %{atom() => Config.Proxy.t()}

  @type t :: %Config{proxies: proxies()}

  defdecoder do
    field(:proxies, with: &Config.to_proxies/1)
  end

  @impl ProxyCat.Config
  def decode(map) do
    map
    |> ProxyCat.VariableInjector.inject(&System.get_env/1)
    |> Starchoice.decode!(Config)
  end

  @doc "Converts map to proxies"
  @spec to_proxies(map()) :: proxies()
  def to_proxies(proxies) do
    Enum.reduce(proxies, %{}, fn {key, proxy_config}, acc ->
      # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
      atom_key = String.to_atom(key)

      config =
        proxy_config
        |> Map.put("key", atom_key)
        |> Starchoice.decode!(Config.Proxy)

      Map.put(acc, atom_key, config)
    end)
  end
end

defimpl ProxyCat.Config.Interface, for: ProxyCat.Config.V1.Config do
  alias ProxyCat.Config.AuthSpec
  alias ProxyCat.Config.V1.Config

  @spec proxy_exists?(Config.t(), atom()) :: boolean()
  def proxy_exists?(%Config{proxies: proxies}, key), do: is_map_key(proxies, key)

  @spec host(Config.t(), atom()) :: {:ok, URI.t()} | {:error, any()}
  def host(%Config{} = config, key) do
    with_proxy(config, key, fn %Config.Proxy{host: host} -> {:ok, host} end)
  end

  @spec update_headers(Config.t(), atom(), :request | :response, [
          ProxyCat.Config.Interface.header()
        ]) :: [ProxyCat.Config.Interface.header()]
  def update_headers(%Config{} = config, key, request_or_response, headers) do
    with_proxy(config, key, fn %Config.Proxy{} = proxy ->
      headers_config =
        case request_or_response do
          :request -> proxy.request_headers
          :response -> proxy.response_headers
        end

      cleared_headers = drop_headers(headers_config, headers)

      headers_config.add ++ cleared_headers
    end)
  end

  defp drop_headers(%Config.Proxy.Headers{drop_all: true}, _headers), do: []

  defp drop_headers(%Config.Proxy.Headers{drop: drop}, headers) do
    Enum.reduce(drop, headers, fn key_to_remove, acc ->
      Enum.reject(acc, fn
        {key, _value} -> String.downcase(key) == String.downcase(key_to_remove)
      end)
    end)
  end

  @spec stateful_proxies(Config.t()) :: [{AuthSpec.t(), atom()}]
  def stateful_proxies(%Config{proxies: proxies}) do
    Enum.reduce(proxies, [], fn {key, %Config.Proxy{auth: auth}}, acc ->
      case auth do
        nil -> acc
        %_auth_spec_struct{} = auth_spec -> [{auth_spec, key} | acc]
      end
    end)
  end

  @spec auth(Config.t(), atom()) :: AuthSpec.t() | nil
  def auth(%Config{} = config, key) do
    case with_proxy(config, key, fn %Config.Proxy{auth: auth} -> {:ok, auth} end) do
      {:error, :no_such_proxy} -> nil
      {:ok, auth} -> auth
    end
  end

  defp with_proxy(%Config{proxies: proxies}, key, function) do
    case Map.fetch(proxies, key) do
      {:ok, %Config.Proxy{} = proxy} ->
        function.(proxy)

      :error ->
        {:error, :no_such_proxy}
    end
  end
end
