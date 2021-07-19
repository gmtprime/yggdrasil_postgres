defmodule Yggdrasil.Config.Postgres do
  @moduledoc """
  This module defines the available settings for PostgreSQL in Yggdrasil.
  """
  use Skogsra

  ##############################
  # Postgres connection settings

  @envdoc """
  Postgres hostname. Defaults to `"localhost"`.
  """
  app_env :hostname, :yggdrasil, [:postgres, :hostname], default: "localhost"

  @envdoc """
  Postgres port. Defaults to `5432`.
  """
  app_env :port, :yggdrasil, [:postgres, :port], default: 5432

  @envdoc """
  Postgres username. Defaults to `"postgres"`.

      iex> Yggdrasil.Config.Postgres.username()
      {:ok, "postgres"}
  """
  app_env :username, :yggdrasil, [:postgres, :username], default: "postgres"

  @envdoc """
  Postgres password. Defaults to `"postgres"`.

      iex> Yggdrasil.Config.Postgres.password()
      {:ok, "postgres"}
  """
  app_env :password, :yggdrasil, [:postgres, :password], default: "postgres"

  @envdoc """
  Postgres database. Defaults to `"postgres"`.

      iex> Yggdrasil.Config.Postgres.database()
      {:ok, "postgres"}
  """
  app_env :database, :yggdrasil, [:postgres, :database], default: "postgres"

  @envdoc """
  Postgres max retries for the backoff algorithm. Defaults to `3`.

  The backoff algorithm is exponential:
  ```
  backoff_time = pow(2, retries) * random(1, slot) * 1_000 ms
  ```
  when `retries <= MAX_RETRIES` and `slot` is given by the configuration
  variable `#{__MODULE__}.slot_size/0` (defaults to `10` secs).

      iex> Yggdrasil.Config.Postgres.max_retries()
      {:ok, 3}
  """
  app_env :max_retries, :yggdrasil, [:postgres, :max_retries], default: 3

  @envdoc """
  Postgres slot size for the backoff algorithm. Defaults to `100`.

      iex> Yggdrasil.Config.Postgres.slot_size()
      {:ok, 10}
  """
  app_env :slot_size, :yggdrasil, [:postgres, :slot_size], default: 10

  @envdoc """
  PostgreSQL amount of publisher connections.

      iex> Yggdrasil.Config.Postgres.publisher_connections()
      {:ok, 1}
  """
  app_env :publisher_connections,
          :yggdrasil,
          [:postgres, :publisher_connections],
          default: 1

  @envdoc """
  PostgreSQL amount of subscriber connections.

      iex> Yggdrasil.Config.Postgres.subscriber_connections()
      {:ok, 1}
  """
  app_env :subscriber_connections,
          :yggdrasil,
          [:postgres, :subscriber_connections],
          default: 1
end
