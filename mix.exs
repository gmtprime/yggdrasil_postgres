defmodule YggdrasilPostgres.MixProject do
  use Mix.Project

  @version "4.0.0"

  def project do
    [
      app: :yggdrasil_postgres,
      version: @version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Yggdrasil.Postgres.Application, []}
    ]
  end

  defp deps do
    [
      {:yggdrasil, "~> 4.0.0"},
      {:postgrex, "~> 0.13"},
      {:connection, "~> 1.0"},
      {:uuid, "~> 1.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.18.4", only: :dev},
      {:credo, "~> 0.9", only: :dev}
    ]
  end

  defp docs do
    [source_url: "https://github.com/gmtprime/yggdrasil_postgres",
     source_ref: "v#{@version}",
     main: Yggdrasil.Postgres.Application]
  end

  defp description do
    """
    Postgres adapter for Yggdrasil.
    """
  end

  defp package do
    [maintainers: ["Alexander de Sousa"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/gmtprime/yggdrasil_postgres"}]
  end
end
