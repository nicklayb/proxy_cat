defmodule ProxyCat.Config.AuthSpec do
  alias ProxyCat.Config.AuthSpec.Jwt
  alias ProxyCat.Config.AuthSpec.Oauth2

  @type t :: Jwt.t() | Oauth2.t()

  def decode(%{"type" => "jwt"} = body) do
    Starchoice.decode!(body, Jwt)
  end

  def decode(%{"type" => "oauth2"} = body) do
    Starchoice.decode!(body, Oauth2)
  end

  def decode(_), do: nil
end
