defmodule YggdrasilPostgres.MixProject do
  use Mix.Project

  @version "5.0.2"
  @root "https://github.com/gmtprime/yggdrasil_postgres"

  def project do
    [
      name: "Yggdrasil for PostgreSQL",
      app: :yggdrasil_postgres,
      version: @version,
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
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
      {:yggdrasil, "~> 5.0"},
      {:skogsra, "~> 2.2"},
      {:postgrex, "~> 0.15"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:credo, "~> 1.2", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: :dev, runtime: false}
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
      source_url: @root,
      source_ref: "v#{@version}",
      main: "readme",
      formatters: ["html"],
      groups_for_modules: groups_for_modules(),
      extras: ["README.md"]
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
