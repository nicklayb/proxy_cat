defmodule ProxyCat.Cache do
  require Logger

  @doc "Runs a command trying to fetch it from cache first, caching it if not"
  @spec cached(any(), [Box.Cache.memoize_option()], function()) :: any()
  def cached(key, options \\ [], function) do
    case cache_ttl() do
      :disabled ->
        function.()

      {:enabled, ttl} ->
        Logger.debug("[#{inspect(__MODULE__)}] Cache enabled with #{ttl} TTL")
        Box.Cache.memoize(__MODULE__, key, Keyword.merge([ttl: ttl], options), function)
    end
  end

  defp cache_ttl do
    :proxy_cat
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:ttl)
    |> then(fn
      value when value > 0 -> {:enabled, value}
      _ -> :disabled
    end)
  end
end
