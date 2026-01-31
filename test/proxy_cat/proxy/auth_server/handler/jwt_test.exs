defmodule ProxyCat.Proxy.AuthServer.Handler.JwtTest do
  use ProxyCat.BaseCase

  alias ProxyCat.Config.AuthSpec
  alias ProxyCat.Http
  alias ProxyCat.Proxy.AuthServer.Handler.Jwt

  @client_id "client_id"
  @refresh_url URI.parse("http://service.com/refresh")
  @auth_spec %AuthSpec.Jwt{
    client_id: @client_id,
    refresh_token: "refresh_token",
    refresh_url: @refresh_url
  }

  setup [:create_jwt, :build_auth_spec, :verify_on_exit!]

  @data_store_options [store_option: :ok]

  @target_key :my_target
  describe "init/2" do
    test "inits handler without stored tokens", %{jwt: spec_token, auth_spec: auth_spec} do
      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :init, fn @target_key, _options ->
        {:ok, @data_store_options}
      end)

      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :read_all, fn keys, @data_store_options ->
        assert_persisted_keys_read(keys)
        {:ok, %{}}
      end)

      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :write_all, fn keys, @data_store_options ->
        assert_persisted_keys_read(keys)
        :ok
      end)

      assert %{
               client_id: @client_id,
               refresh_token: auth_spec.refresh_token,
               access_token: spec_token,
               refresh_url: @refresh_url,
               key: @target_key,
               data_store_options: @data_store_options,
               expires_at: jwt_expires_at(spec_token),
               inserted_at: jwt_inserted_at(spec_token)
             } == Jwt.init(auth_spec, @target_key)

      assert_receive(:check_expiration)
    end

    test "inits handler with stored tokens", %{auth_spec: auth_spec} do
      data_store_options = [store_option: :ok]

      stored_token = jwt(inserted_at: relative_time(hour: 3))

      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :init, fn @target_key, _options ->
        {:ok, data_store_options}
      end)

      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :read_all, fn keys, @data_store_options ->
        assert_persisted_keys_read(keys)
        {:ok, %{access_token: stored_token, refresh_token: "refresh_token"}}
      end)

      assert %{
               client_id: @client_id,
               refresh_token: "refresh_token",
               access_token: stored_token,
               refresh_url: @refresh_url,
               key: @target_key,
               data_store_options: @data_store_options,
               expires_at: jwt_expires_at(stored_token),
               inserted_at: jwt_inserted_at(stored_token)
             } == Jwt.init(auth_spec, @target_key)

      assert_receive(:check_expiration)
    end

    @tag jwt_inserted_at: [hour: 3]
    test "inits handler with spec tokens if more recent than stored", %{
      jwt: spec_token,
      auth_spec: auth_spec
    } do
      data_store_options = [store_option: :ok]

      stored_token = jwt(inserted_at: utc_now())

      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :init, fn @target_key, _options ->
        {:ok, data_store_options}
      end)

      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :read_all, fn keys, @data_store_options ->
        assert_persisted_keys_read(keys)
        {:ok, %{access_token: stored_token, refresh_token: "refresh_token"}}
      end)

      assert %{
               client_id: @client_id,
               refresh_token: "refresh_token",
               access_token: spec_token,
               refresh_url: @refresh_url,
               key: @target_key,
               data_store_options: @data_store_options,
               expires_at: jwt_expires_at(spec_token),
               inserted_at: jwt_inserted_at(spec_token)
             } == Jwt.init(auth_spec, @target_key)

      assert_receive(:check_expiration)
    end
  end

  describe "handle_info/2" do
    test "handles :check_expiration message and only schedule expiration timer if not expiring",
         %{jwt_expires_at: jwt_expires_at} do
      assert %{expires_at: ^jwt_expires_at, expiration_timer: timer} =
               Jwt.handle_info(:check_expiration, %{expires_at: jwt_expires_at})

      assert is_reference(timer)
      Process.cancel_timer(timer)
    end

    @tag jwt_expires_at: [minute: 1]
    test "handles :check_expiration message and refreshes",
         %{auth_spec: auth_spec, jwt: spec_token} do
      state = %{
        client_id: @client_id,
        refresh_token: auth_spec.refresh_token,
        access_token: spec_token,
        refresh_url: @refresh_url,
        key: @target_key,
        data_store_options: @data_store_options,
        expires_at: jwt_expires_at(spec_token),
        inserted_at: jwt_inserted_at(spec_token)
      }

      new_token = jwt([])
      new_refresh_token = "new_refresh_token"

      Mox.expect(ProxyCat.Http.Adapter.Mock, :request, fn %Http.Request{
                                                            headers: [],
                                                            body: nil,
                                                            method: :post,
                                                            url: @refresh_url
                                                          },
                                                          [
                                                            json: %{
                                                              client_id: "client_id",
                                                              refresh_token: "refresh_token",
                                                              grant_type: "refresh_token"
                                                            }
                                                          ] ->
        {:ok,
         %Http.Response{
           status: 200,
           headers: [],
           body: %{"access_token" => new_token, "refresh_token" => new_refresh_token}
         }}
      end)

      Mox.expect(ProxyCat.DataStore.Adapter.Mock, :write_all, fn keys, @data_store_options ->
        assert_persisted_keys_read(keys)
        :ok
      end)

      expires_at = jwt_expires_at(new_token)
      inserted_at = jwt_inserted_at(new_token)

      assert %{
               client_id: @client_id,
               refresh_token: ^new_refresh_token,
               access_token: ^new_token,
               refresh_url: @refresh_url,
               key: @target_key,
               data_store_options: @data_store_options,
               expires_at: ^expires_at,
               inserted_at: ^inserted_at,
               expiration_timer: expiration_timer
             } = Jwt.handle_info(:check_expiration, state)

      assert is_reference(expiration_timer)
      Process.cancel_timer(expiration_timer)
    end

    test "returns state as is for unknown message" do
      assert %{} == Jwt.handle_info(:unknown_message, %{})
    end
  end

  describe "store/3" do
    test "stores entry into state" do
      assert %{key: :value} == Jwt.store(%{}, :key, :value)
      assert %{key: :value} == Jwt.store(%{key: :old_value}, :key, :value)
    end
  end

  describe "retrieve/2" do
    test "retrieves key from state" do
      assert nil == Jwt.retrieve(%{}, :key)
      assert :value == Jwt.retrieve(%{key: :value}, :key)
    end
  end

  @persisted_keys ~w(access_token refresh_token)a
  defp assert_persisted_keys_read(keys) when is_list(keys) do
    Assertions.assert_lists_equal(keys, @persisted_keys)
  end

  defp assert_persisted_keys_read(key_mapping) when is_map(key_mapping) do
    key_mapping
    |> Map.keys()
    |> assert_persisted_keys_read()
  end

  defp build_auth_spec(context) do
    [auth_spec: %AuthSpec.Jwt{@auth_spec | access_token: Map.fetch!(context, :jwt)}]
  end
end
