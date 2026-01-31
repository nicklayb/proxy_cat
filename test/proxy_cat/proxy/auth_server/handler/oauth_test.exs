defmodule ProxyCat.Proxy.AuthServer.Handler.OauthTest do
  use ProxyCat.BaseCase

  alias ProxyCat.Config.AuthSpec
  alias ProxyCat.Proxy.AuthServer.Handler.Oauth

  @authorize_url URI.parse("http://service.com/oauth/authorize")
  @auth_spec %AuthSpec.Oauth2{
    authorize_url: @authorize_url
  }

  setup [:verify_on_exit!, :setup_auth_spec]

  @data_store_options [store_option: :ok]
  @persisted_keys ~w(access_token refresh_token scope expires_in token_type)a

  @target_key :my_target
  describe "init/2" do
    test "inits without tokens if nothing stored", %{auth_spec: auth_spec} do
      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :init, fn @target_key, _options ->
        {:ok, @data_store_options}
      end)

      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :read_all, fn keys, @data_store_options ->
        assert_persisted_keys_read(keys)
        {:ok, %{}}
      end)

      assert %{data_store_options: @data_store_options, key: @target_key} ==
               Oauth.init(auth_spec, @target_key)
    end

    test "inits with tokens if store has some", %{auth_spec: auth_spec} do
      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :init, fn @target_key, _options ->
        {:ok, @data_store_options}
      end)

      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :read_all, fn keys, @data_store_options ->
        assert_persisted_keys_read(keys)

        {:ok,
         %{
           access_token: "access_token",
           refresh_token: "refresh_token",
           expires_in: "expires_in",
           token_type: "token_type",
           scope: "scope"
         }}
      end)

      assert %{
               data_store_options: @data_store_options,
               key: @target_key,
               access_token: "access_token",
               refresh_token: "refresh_token",
               expires_in: "expires_in",
               token_type: "token_type",
               scope: "scope"
             } ==
               Oauth.init(auth_spec, @target_key)
    end
  end

  describe "handle_info/2" do
    test "returns state as is" do
      assert %{} == Oauth.handle_info(:message, %{})
    end
  end

  describe "store/3" do
    test "store unpersisted keys without data store" do
      assert %{key: :value} == Oauth.store(%{}, :key, :value)
      assert %{key: :value} == Oauth.store(%{key: :old_value}, :key, :value)
    end

    for key <- @persisted_keys do
      test "store #{key} in data store" do
        value = "some_value"

        Mox.expect(ProxyCat.DataStore.Adapter.Mock, :write_all, fn %{unquote(key) => ^value},
                                                                   @data_store_options ->
          :ok
        end)

        assert %{unquote(key) => value, data_store_options: @data_store_options} ==
                 Oauth.store(%{data_store_options: @data_store_options}, unquote(key), value)
      end
    end
  end

  describe "retrieve/2" do
    test "retrieves key from state" do
      assert nil == Oauth.retrieve(%{}, :key)
      assert :value == Oauth.retrieve(%{key: :value}, :key)
    end
  end

  defp setup_auth_spec(_context) do
    [auth_spec: @auth_spec]
  end

  defp assert_persisted_keys_read(keys) when is_list(keys) do
    Assertions.assert_lists_equal(keys, @persisted_keys)
  end

  defp assert_persisted_keys_read(key_mapping) when is_map(key_mapping) do
    key_mapping
    |> Map.keys()
    |> assert_persisted_keys_read()
  end
end
