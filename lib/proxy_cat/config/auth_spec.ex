defmodule ProxyCat.Config.AuthSpec do
  @moduledoc """
  AuthSpec entrypoint decoder. All configuration versions
  must be building those down if they support auth.
  """
  alias ProxyCat.Config.AuthSpec.Jwt
  alias ProxyCat.Config.AuthSpec.Oauth2

  @type t :: Jwt.t() | Oauth2.t()

  @doc "Decodes map into appropriate auth spec"
  @spec decode(map()) :: t() | nil
  def decode(%{"type" => "jwt"} = body) do
    Starchoice.decode!(body, Jwt)
  end

  def decode(%{"type" => "oauth2"} = body) do
    Starchoice.decode!(body, Oauth2)
  end

  def decode(_unsupported_auth), do: nil
end
