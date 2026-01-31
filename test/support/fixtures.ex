defmodule ProxyCat.Support.Fixtures do
  @moduledoc """
  Fixtures put in place some foundation data. All of the functions
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
end
