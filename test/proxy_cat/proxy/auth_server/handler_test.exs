defmodule ProxyCat.Proxy.AuthServer.HandlerTest do
  use ProxyCat.BaseCase, async: true

  alias ProxyCat.Config.AuthSpec
  alias ProxyCat.Proxy.AuthServer.Handler

  describe "handler/1" do
    test "gets proper handler for auth spec" do
      assert ProxyCat.Proxy.AuthServer.Handler.Jwt == Handler.handler(%AuthSpec.Jwt{})
      assert ProxyCat.Proxy.AuthServer.Handler.Oauth == Handler.handler(%AuthSpec.Oauth2{})
    end
  end
end
