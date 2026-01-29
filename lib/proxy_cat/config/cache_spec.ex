defmodule ProxyCat.Config.CacheSpec do
  @moduledoc """
  Cache specification per proxy
  """
  use Starchoice.Decoder
  alias ProxyCat.Config.CacheSpec

  defstruct [:ttl]

  @type t :: %CacheSpec{
          ttl: non_neg_integer()
        }

  defdecoder do
    field(:ttl, with: &CacheSpec.decode_ttl/1)
  end

  @doc """
  Decodes TTL value to milliseconds with the following formats

  - 1m (1 minute)
  - 2h (2 hours)
  - 10 (10 milliseconds)

  ## Examples

      iex> ProxyCat.Config.CacheSpec.decode_ttl("1m")
      60000

      iex> ProxyCat.Config.CacheSpec.decode_ttl("30s")
      30000

      iex> ProxyCat.Config.CacheSpec.decode_ttl("3s")
      3000
  """
  @spec decode_ttl(String.t()) :: non_neg_integer()
  def decode_ttl(string) when is_binary(string) do
    string
    |> Box.Integer.from_duration_string()
    |> div(:timer.seconds(1))
  end
end
