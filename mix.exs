defmodule UnsplashProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :unsplash_proxy,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {UnsplashProxy.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:plug, "~> 1.19.1"},
      {:bandit, "~> 1.0"},
      {:box, git: "https://github.com/nicklayb/box_ex.git", tag: "0.17.0"}
    ]
  end
end
