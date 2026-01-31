defmodule ProxyCat.VariableInjector.Provider.SystemEnvironmentTest do
  use ProxyCat.BaseCase, async: true

  describe "provider/1" do
    setup [:set_environment]

    @test_env "TEST_ENV"
    @missing_env "MISSING"
    @tag [environment: %{@test_env => "Value", @missing_env => nil}]
    test "gets value from environment" do
      assert "Value" == System.get_env(@test_env)
      assert nil == System.get_env(@missing_env)
    end
  end
end
