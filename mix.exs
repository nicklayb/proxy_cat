defmodule ProxyCat.MixProject do
  use Mix.Project

  @version "./VERSION"
           |> File.read!()
           |> String.trim()
  def project do
    [
      app: :proxy_cat,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ProxyCat.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:plug, "~> 1.19.1"},
      {:bandit, "~> 1.0"},
      {:box, git: "https://github.com/nicklayb/box_ex.git", tag: "0.17.3"},
      {:yaml_elixir, "~> 2.12.0"},
      {:starchoice, "~> 0.3.0"},
      {:joken, "~> 2.6"},
      {:credo, "~> 1.7", only: ~w(dev test)a, runtime: false},
      {:dialyxir, "~> 1.4", only: ~w(dev test)a, runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:assertions, "~> 0.22", only: :test},
      {:file_system, "~> 1.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def cli do
    [preferred_envs: [lint: :test]]
  end

  defp aliases do
    [
      lint: ["compile --warning-as-errors", "credo --strict", "dialyzer", "test"]
    ]
  end
end
