defmodule YggdrasilPostgres.MixProject do
  use Mix.Project

  @version "4.1.1"
  @root "https://github.com/gmtprime/yggdrasil_postgres"

  def project do
    [
      app: :yggdrasil_postgres,
      version: @version,
      elixir: "~> 1.6",
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
      {:yggdrasil, "~> 4.1"},
      {:postgrex, "~> 0.13"},
      {:connection, "~> 1.0"},
      {:uuid, "~> 1.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.18.4", only: :dev},
      {:credo, "~> 0.10", only: :dev}
    ]
  end

  #########
  # Package

  defp package do
    [
      description: "PostgreSQL adapter for Yggdrasil (pub/sub)",
      files: ["lib", "mix.exs", "images", "README.md"],
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
      main: Yggdrasil.Postgres.Application,
      formatters: ["html"],
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    [
      "Application": [
        Yggdrasil.Postgres.Application
      ],
      "Adapter": [
        Yggdrasil.Settings.Postgres,
        Yggdrasil.Adapter.Postgres
      ],
      "Subscriber adapter": [
        Yggdrasil.Subscriber.Adapter.Postgres
      ],
      "Publisher adapter": [
        Yggdrasil.Publisher.Adapter.Postgres
      ],
    ]
  end
end
