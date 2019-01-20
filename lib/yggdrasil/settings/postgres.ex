defmodule Yggdrasil.Settings.Postgres do
  @moduledoc """
  This module defines the available settings for PostgreSQL in Yggdrasil.
  """
  use Skogsra

  ##########################################################
  # Postgres connection default variables for default domain

  @envdoc """
  Postgres hostname. Defaults to `"localhost"`.
  """
  app_env :yggdrasil_postgres_hostname, :yggdrasil, [:postgres, :hostname],
    default: "localhost"

  @envdoc """
  Postgres port. Defaults to `5432`.
  """
  app_env :yggdrasil_postgres_port, :yggdrasil, [:postgres, :port],
    default: 5432

  @envdoc """
  Postgres username. Defaults to `"postgres"`.
  """
  app_env :yggdrasil_postgres_username, :yggdrasil, [:postgres, :username],
    default: "postgres"

  @envdoc """
  Postgres password. Defaults to `"postgres"`.
  """
  app_env :yggdrasil_postgres_password, :yggdrasil, [:postgres, :password],
    default: "postgres"

  @envdoc """
  Postgres database. Defaults to `"postgres"`.
  """
  app_env :yggdrasil_postgres_database, :yggdrasil, [:postgres, :database],
    default: "postgres"

  @envdoc """
  Postgres max retries for the backoff algorithm. Defaults to `12`.

  The backoff algorithm is exponential:
  ```
  backoff_time = pow(2, retries) * random(1, slot) ms
  ```
  when `retries <= MAX_RETRIES` and `slot` is given by the configuration
  variable `#{__MODULE__}.yggdrasil_postgres_slot_size/0` (defaults to `100`
  ms).
  """
  app_env :yggdrasil_postgres_max_retries,
          :yggdrasil,
          [:postgres, :max_retries],
          default: 12

  @envdoc """
  Postgres slot size for the backoff algorithm. Defaults to `100`.
  """
  app_env :yggdrasil_postgres_slot_size, :yggdrasil, [:postgres, :slot_size],
    default: 100
end
