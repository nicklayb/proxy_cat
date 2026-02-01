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

  describe "handle_info/2" do
    @tag config_file: @config_file
    test "hot reloads when it receives :modified and :closed events", %{
      server_pid: server_pid,
      server_state: server_state
    } do
      assert {:stop, :normal, state} =
               [events: [:modified, :closed]]
               |> file_event(server_state)
               |> Server.handle_info(server_state)
    end

    @tag config_file: @config_file
    test "ignores if it's missing either :modified or :closed events", %{
      server_pid: server_pid,
      server_state: server_state
    } do
      assert {:noreply, ^server_state} =
               [events: [:closed]]
               |> file_event(server_state)
               |> Server.handle_info(server_state)

      assert {:noreply, ^server_state} =
               [events: [:modified]]
               |> file_event(server_state)
               |> Server.handle_info(server_state)
    end

    @tag config_file: @config_file
    test "ignores if either file_location or pid is different", %{
      server_pid: server_pid,
      server_state: server_state
    } do
      assert {:noreply, ^server_state} =
               [events: [:modified, :closed], file_location: "dragon.txt"]
               |> file_event(server_state)
               |> Server.handle_info(server_state)

      assert {:noreply, ^server_state} =
               [events: [:modified, :closed], watcher_pid: self()]
               |> file_event(server_state)
               |> Server.handle_info(server_state)
    end
  end

  defp file_event(options, server_state) do
    watcher_pid = Keyword.get(options, :watcher_pid, server_state.watcher_pid)
    file_location = Keyword.get(options, :file_location, server_state.file_location)
    events = Keyword.fetch!(options, :events)

    {:file_event, watcher_pid, {file_location, events}}
  end

  defp start_server(_context) do
    Mox.expect(ProxyCat.Config.Reader.Mock, :read, fn @config_file ->
      {:ok, @config}
    end)

    pid = start_supervised!({Server, []})

    assert is_pid(pid)

    [server_pid: pid, server_state: :sys.get_state(pid)]
  end
end
