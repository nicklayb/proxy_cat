defmodule ProxyCat.Proxy.AuthServer.Handler do
  @moduledoc """
  Handler behaviour to configure a auth state for a
  specific auth spec
  """
  alias ProxyCat.Config.AuthSpec
  alias ProxyCat.Proxy.AuthServer.Handler

  @callback init(struct(), atom()) :: map()
  @callback store(map(), atom(), any()) :: map()
  @callback retrieve(map(), atom()) :: map()
  @callback handle_info(any(), map()) :: map()

  @type t :: Handler.Jwt | Handler.Default

  @doc "Returns appropriate handler for auth spec"
  @spec handler(AuthSpec.t()) :: t()
  def handler(%AuthSpec.Jwt{}), do: Handler.Jwt
  def handler(%AuthSpec.Oauth2{}), do: Handler.Oauth
end
