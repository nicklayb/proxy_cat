defmodule ProxyCat.Support.Jwt do
  @moduledoc """
  Helper module to work with JWT tokens
  """
  alias ProxyCat.Support

  @type token :: String.t()

  @doc "Generates a JWT with optional specific timestamps"
  @spec jwt([{:inserted_at, DateTime.t()} | {:expires_at, DateTime.t()}]) :: token()
  def jwt(options) do
    inserted_at =
      Keyword.get_lazy(options, :inserted_at, fn ->
        Support.Date.utc_now()
      end)

    expires_in =
      Keyword.get_lazy(options, :expires_at, fn ->
        Support.Date.relative_time(inserted_at, hour: 3)
      end)

    {:ok, token, _claims} =
      Joken.generate_and_sign(%{}, %{
        "iat" => DateTime.to_unix(inserted_at),
        "exp" => DateTime.to_unix(expires_in)
      })

    token
  end

  defp jwt_claim(token, claim) do
    {:ok, claims} = Joken.peek_claims(token)
    Map.fetch!(claims, claim)
  end

  @doc "Extract inserted at timestamp as date time"
  @spec jwt_inserted_at(token()) :: DateTime.t()
  def jwt_inserted_at(token) do
    token
    |> jwt_claim("iat")
    |> DateTime.from_unix!()
  end

  @doc "Extract expires at timestamp as date time"
  @spec jwt_expires_at(token()) :: DateTime.t()
  def jwt_expires_at(token) do
    token
    |> jwt_claim("exp")
    |> DateTime.from_unix!()
  end
end
