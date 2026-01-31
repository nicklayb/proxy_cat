defmodule ProxyCat.Support.Date do
  @moduledoc """
  Helper functions to work with time
  """

  @doc "Gets current date as UTC"
  @spec utc_now() :: DateTime.t()
  def utc_now, do: DateTime.utc_now()

  @doc "Generates a date relative to a base date"
  @spec relative_time(DateTime.t(), Keyword.t()) :: DateTime.t()
  def relative_time(date \\ utc_now(), shift) do
    DateTime.shift(date, shift)
  end
end
