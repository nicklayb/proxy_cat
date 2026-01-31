defmodule ProxyCat.Cache do
  @moduledoc """
  Cache helpers functions
  """
  require Logger

  @type cached_options :: Box.Cache.memoize_option() | Box.Cache.insert_option()

  @doc "Runs a command trying to fetch it from cache first, caching it if not"
  @spec cached(any(), [cached_options()], function()) :: any()
  def cached(key, options \\ [], function) do
    case cache_ttl(options) do
      :disabled ->
        function.()

      {:enabled, ttl} ->
        Logger.debug("[#{inspect(__MODULE__)}] Cache enabled with #{ttl} TTL")
        Box.Cache.memoize(__MODULE__, key, Keyword.merge([ttl: ttl], options), function)
    end
  end

  defp cache_ttl(options) do
    case Keyword.get(options, :ttl) do
      value when value > 0 -> {:enabled, value}
      _other -> :disabled
    end
  end
end
