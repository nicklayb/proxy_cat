defmodule ProxyCat.Support.Async do
  @moduledoc """
  Helper function to work with asynchronous behaviours
  """

  @type option :: {:sleep, non_neg_integer()} | {:tries, non_neg_integer()}
  @doc "Runs a function until it succeeds"
  @spec wait_until((-> :ok), [option()]) :: :ok
  def wait_until(function, options \\ [])

  def wait_until(function, options) do
    wait_until(function, 0, options)
  end

  @default_tries 10
  @default_sleep 100

  defp wait_until(function, current_tries, options) do
    if current_tries >= Keyword.get(options, :tries, @default_tries) do
      raise RuntimeError, "Maximum tries reached"
    else
      function.()
      :ok
    end
  rescue
    ExUnit.AssertionError ->
      options
      |> Keyword.get(:sleep, @default_sleep)
      |> Process.sleep()

      wait_until(function, current_tries + 1, options)
  end
end
