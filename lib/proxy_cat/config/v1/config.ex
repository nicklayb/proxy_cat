defmodule ProxyCat.Config.V1.Config do
  defstruct proxies: %{}
  alias ProxyCat.Config.V1.Config

  use Starchoice.Decoder

  defdecoder do
    field(:proxies, with: &Config.to_proxies/1)
  end

  def decode(map) do
    map
    |> ProxyCat.VariableInjector.inject(&System.get_env/1)
    |> Starchoice.decode!(Config)
  end

  def to_proxies(proxies) do
    Enum.reduce(proxies, %{}, fn {key, proxy_config}, acc ->
      atom_key = String.to_atom(key)

      config =
        proxy_config
        |> Map.put("key", atom_key)
        |> Starchoice.decode!(Config.Proxy)

      Map.put(acc, atom_key, config)
    end)
  end

  def with_proxy(%Config{proxies: proxies}, key, function) do
    case Map.fetch(proxies, key) do
      {:ok, %Config.Proxy{} = proxy} ->
        function.(proxy)

      :error ->
        {:error, :no_such_host}
    end
  end
end

defimpl ProxyCat.Config.Interface, for: ProxyCat.Config.V1.Config do
  alias ProxyCat.Config.V1.Config

  def proxy_exists?(%Config{proxies: proxies}, key), do: is_map_key(proxies, key)

  def host(%Config{} = config, key) do
    Config.with_proxy(config, key, fn %Config.Proxy{host: host} -> {:ok, host} end)
  end

  def update_headers(%Config{} = config, key, request_or_response, headers) do
    Config.with_proxy(config, key, fn %Config.Proxy{} = proxy ->
      headers_config =
        case request_or_response do
          :request -> proxy.request_headers
          :response -> proxy.response_headers
        end

      cleared_headers = drop_headers(headers_config, headers)

      headers_config.add ++ cleared_headers
    end)
  end

  defp drop_headers(%Config.Proxy.Headers{drop_all: true}, _), do: []

  defp drop_headers(%Config.Proxy.Headers{drop: drop}, headers) do
    Enum.reduce(drop, headers, fn key_to_remove, acc ->
      Enum.reject(acc, fn
        {key, _} -> String.downcase(key) == String.downcase(key_to_remove)
      end)
    end)
  end

  def stateful_proxies(%Config{proxies: proxies}) do
    Enum.reduce(proxies, [], fn {key, %Config.Proxy{auth: auth}}, acc ->
      case auth do
        nil -> acc
        %_{} = auth_spec -> [{auth_spec, key} | acc]
      end
    end)
  end

  def auth(%Config{} = config, key) do
    Config.with_proxy(config, key, fn %Config.Proxy{auth: auth} -> {:ok, auth} end)
  end
end
