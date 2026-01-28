defmodule ProxyCat.Routing.V1.Config do
  defstruct proxies: %{}
  alias ProxyCat.Routing.V1.Config

  use Starchoice.Decoder

  defdecoder do
    field(:proxies, with: &Config.to_proxies/1)
  end

  def decode(map) do
    Starchoice.decode!(map, Config)
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

defimpl ProxyCat.Routing.Interface, for: ProxyCat.Routing.V1.Config do
  alias ProxyCat.Routing.V1.Config

  def proxy_exists?(%Config{proxies: proxies}, key), do: is_map_key(proxies, key)

  def host(%Config{} = config, key) do
    Config.with_proxy(config, key, fn %Config.Proxy{host: host} -> {:ok, host} end)
  end

  def update_headers(%Config{} = config, key, request_or_response, headers) do
    Config.with_proxy(config, key, fn %Config.Proxy{} = proxy ->
      %Config.Proxy.Headers{
        add: add,
        drop: drop
      } =
        case request_or_response do
          :request -> proxy.request_headers
          :response -> proxy.response_headers
        end

      cleared_headers =
        Enum.reduce(drop, headers, fn key_to_remove, acc ->
          Enum.reject(acc, fn
            {key, _} -> String.downcase(key) == String.downcase(key_to_remove)
          end)
        end)

      Enum.reduce(add, cleared_headers, fn {key, value}, acc ->
        filled_value = ProxyCat.VariableInjector.inject(value)
        [{key, filled_value} | acc]
      end)
    end)
  end

  def stateful_proxies(%Config{proxies: proxies}) do
    Enum.reduce(proxies, [], fn {key, %Config.Proxy{auth: auth}}, acc ->
      case auth do
        nil -> acc
        %auth_spec{} -> [{auth_spec, key} | acc]
      end
    end)
  end

  def auth(%Config{} = config, key) do
    Config.with_proxy(config, key, fn %Config.Proxy{auth: auth} -> {:ok, auth} end)
  end
end
