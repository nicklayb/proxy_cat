defmodule ProxyCat.Support.TestFixture do
  @moduledoc """
  Test fixtures put in place some foundation data. All of the functions
  below are expected to be used in `setup` statements.
  """
  alias ProxyCat.Support

  @doc "Updates the system environment resetting it back after tests"
  @spec set_environment(map()) :: :ok
  def set_environment(context) do
    environment = Map.get(context, :environment, %{})

    previous_variables =
      Enum.reduce(environment, %{}, fn {key, _new_value}, acc ->
        value = System.get_env(key)
        Map.put(acc, key, value)
      end)

    set_all_environment(environment)

    ExUnit.Callbacks.on_exit(fn ->
      set_all_environment(previous_variables)
    end)
  end

  defp set_all_environment(mapping) do
    Enum.each(mapping, fn
      {key, nil} ->
        System.delete_env(key)

      {key, old_value} ->
        System.put_env(key, old_value)
    end)
  end

  @doc "Creates a JWT in state with timestamps"
  @spec create_jwt(map()) :: [
          {:jwt, Support.Jwt.token()},
          {:jwt_expires_at, DateTime.t()},
          {:jwt_inserted_at, DateTime.t()}
        ]
  def create_jwt(%{jwt: _already_setup_jwt}) do
    []
  end

  def create_jwt(context) do
    inserted_at_shift = Map.get(context, :jwt_inserted_at, [])
    expires_at_shift = Map.get(context, :jwt_expires_at, hour: 3)
    inserted_at = DateTime.shift(Support.Date.utc_now(), inserted_at_shift)
    expires_at = DateTime.shift(Support.Date.utc_now(), expires_at_shift)

    [
      jwt: Support.Jwt.jwt(inserted_at: inserted_at, expires_at: expires_at),
      jwt_expires_at: expires_at,
      jwt_inserted_at: inserted_at
    ]
  end

  @doc "Sets configuration using a `config` tag"
  @spec set_config(map()) :: :ok
  def set_config(context) do
    context
    |> Map.get(:config, [])
    |> Enum.each(fn {application, configs} ->
      Enum.each(configs, fn {key, configurations} ->
        Support.Env.set_config(application, key, configurations)
      end)
    end)
  end

  @doc "Sets config file in application's config"
  @spec set_config_file(map()) :: :ok
  def set_config_file(context) do
    config_file = Map.fetch!(context, :config_file)
    Support.Env.set_config(:proxy_cat, ProxyCat.Config, file: config_file)
  end
end
