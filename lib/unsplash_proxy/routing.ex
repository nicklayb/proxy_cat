defmodule ProxyCat.Routing do
  alias ProxyCat.Routing

  def read_yaml do
    with {:ok, %{"version" => version} = body} <- YamlElixir.read_from_file(file_location()) do
      {:ok, decode_by_version(version, body)}
    end
  end

  def proxy_exists?(%Routing.V1.Config{proxies: proxies}, key) do
    is_map_key(proxies, key)
  end

  def proxy_host(%Routing.V1.Config{proxies: proxies}, key) do
    case Map.fetch(proxies, key) do
      {:ok, %Routing.V1.Config.Proxy{host: host}} ->
        {:ok, host}

      :error ->
        {:error, :no_such_host}
    end
  end

  defp decode_by_version(1, body) do
    Routing.V1.Config.decode(body)
  end

  defp decode_by_version(version, _) do
    raise "Unsupported version #{version}"
  end

  defp file_location do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:config_yaml)
  end
end
