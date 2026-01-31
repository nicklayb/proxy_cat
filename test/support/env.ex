defmodule ProxyCat.Support.Env do
  @moduledoc """
  Helper functions to work environment mocking
  """

  @doc "Sets application's configuration for test's duration"
  @spec set_config(atom(), atom(), Keyword.t()) :: :ok
  def set_config(application_key, key, configurations) do
    application_key
    |> get_current_config()
    |> tap(fn config ->
      ExUnit.Callbacks.on_exit({ProxyCat.Support.Env, application_key}, fn ->
        Application.put_all_env(config)
      end)
    end)
    |> Config.__merge__([{application_key, [{key, configurations}]}])
    |> Application.put_all_env()
  end

  defp get_current_config(application_key) do
    [{application_key, Application.get_all_env(application_key)}]
  end
end
