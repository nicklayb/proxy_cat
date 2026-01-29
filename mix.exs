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
      deps: deps()
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
      {:box, git: "https://github.com/nicklayb/box_ex.git", tag: "0.17.0"},
      {:yaml_elixir, "~> 2.12.0"},
      {:starchoice, "~> 0.3.0"},
      {:joken, "~> 2.6"},
      {:credo, "~> 1.7", only: ~w(dev test)a, runtime: false},
      {:dialyxir, "~> 1.4", only: ~w(dev test)a, runtime: false}
    ]
  end
end
