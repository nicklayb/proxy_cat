defmodule ProxyCat.Config.ServerTest do
  use ProxyCat.BaseCase, async: false

  alias ProxyCat.Config.Server

  setup [
    :set_config,
    :set_mox_global,
    :set_config_file,
    :start_server,
    :verify_on_exit!
  ]

  @config_file config_file!(1, "basic.yml")
  @config elem(ProxyCat.Config.Reader.Yaml.read(@config_file), 1)
  describe "start_link/1" do
    @tag config_file: @config_file
    test "starts config server with real file", %{server_pid: server_pid} do
      assert Process.alive?(server_pid)
    end
  end

  describe "reload/0" do
    @tag config_file: @config_file
    test "reloads server by stopping it", %{server_pid: server_pid} do
      Server.reload()
      refute Process.alive?(server_pid)
    end
  end

  describe "config/0" do
    @tag config_file: @config_file
    test "returns configuration" do
      assert %ProxyCat.Config.V1.Config{proxies: %{dragons: _proxy}} = Server.config()
    end
  end

  defp start_server(_context) do
    Mox.expect(ProxyCat.Config.Reader.Mock, :read, fn @config_file ->
      {:ok, @config}
    end)

    pid = start_supervised!({Server, []})

    assert is_pid(pid)

    [server_pid: pid]
  end
end
