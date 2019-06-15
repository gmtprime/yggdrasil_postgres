defmodule YggdrasilPostgres.MixProject do
  use Mix.Project

  @version "5.0.0"
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
      {:postgrex, "~> 0.14"},
      {:ex_doc, "~> 0.20", only: :dev},
      {:credo, "~> 1.0", only: :dev}
    ]
  end

  #########
  # Package

  defp package do
    [
      description: "PostgreSQL adapter for Yggdrasil (pub/sub)",
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Alexander de Sousa"],
      licenses: ["MIT"],
      links: %{
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
      ]
    ]
  end
end
