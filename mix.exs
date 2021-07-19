defmodule YggdrasilPostgres.MixProject do
  use Mix.Project

  @version "6.0.0"
  @root "https://github.com/gmtprime/yggdrasil_postgres"

  def project do
    [
      name: "Yggdrasil for PostgreSQL",
      app: :yggdrasil_postgres,
      version: @version,
      elixir: "~> 1.12",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  #############
  # Application

  def application do
    [
      extra_applications: [:logger],
      mod: {Yggdrasil.Postgres.Application, []}
    ]
  end

  defp deps do
    [
      {:yggdrasil, "~> 6.0"},
      {:skogsra, "~> 2.3"},
      {:postgrex, "~> 0.15"},
      {:ex_doc, "~> 0.24", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  def dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/yggdrasil_postgres.plt"}
    ]
  end

  #########
  # Package

  defp package do
    [
      description: "PostgreSQL adapter for Yggdrasil (pub/sub)",
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md"],
      maintainers: ["Alexander de Sousa"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@root}/blob/master/CHANGELOG.md",
        "Github" => @root
      }
    ]
  end

  ###############
  # Documentation

  defp docs do
    [
      main: "readme",
      source_url: @root,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    [
      "PostgreSQL Adapter Settings": [
        Yggdrasil.Settings.Postgres,
        Yggdrasil.Adapter.Postgres
      ],
      "Subscriber adapter": [
        Yggdrasil.Subscriber.Adapter.Postgres
      ],
      "Publisher adapter": [
        Yggdrasil.Publisher.Adapter.Postgres
      ],
      "PostgreSQL Connection Handling": [
        Yggdrasil.Postgres.Connection,
        Yggdrasil.Postgres.Connection.Pool,
        Yggdrasil.Postgres.Connection.Generator
      ]
    ]
  end
end
