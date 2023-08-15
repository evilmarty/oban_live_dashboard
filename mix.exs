defmodule Oban.LiveDashboard.MixProject do
  use Mix.Project

  @source_url "https://github.com/evilmarty/oban_live_dashboard"

  def project do
    [
      app: :oban_live_dashboard,
      version: "0.1.1",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "A simple Phoenix Live Dashboard for Oban jobs",
      source_url: @source_url
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:floki, ">= 0.30.0", only: :test},
      {:ecto_sqlite3, ">= 0.0.0", only: :test},
      {:oban, "~> 2.15"}
    ]
  end

  defp package do
    [
      maintainers: ["Marty Zalega"],
      licenses: ["Apache-2.0"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      links: %{
        GitHub: @source_url
      }
    ]
  end
end
