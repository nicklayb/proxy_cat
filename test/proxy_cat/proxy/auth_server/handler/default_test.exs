defmodule ProxyCat.Proxy.AuthServer.Handler.DefaultTest do
  use ProxyCat.BaseCase, async: true

  alias ProxyCat.Proxy.AuthServer.Handler.Default

  describe "init/2" do
    test "inits handler to empty map" do
      assert %{} == Default.init(%{}, :key)
    end
  end

  describe "handle_info/2" do
    test "returns state as is" do
      assert %{} == Default.handle_info(:message, %{})
    end
  end

  describe "store/3" do
    test "stores entry into state" do
      assert %{key: :value} == Default.store(%{}, :key, :value)
      assert %{key: :value} == Default.store(%{key: :old_value}, :key, :value)
    end
  end

  describe "retrieve/2" do
    test "retrieves key from state" do
      assert nil == Default.retrieve(%{}, :key)
      assert :value == Default.retrieve(%{key: :value}, :key)
    end
  end
end
