defmodule Yggdrasil.Postgres.Application do
  @moduledoc """
  Module that defines Yggdrasil with Postgres support.

  ![demo](https://raw.githubusercontent.com/gmtprime/yggdrasil_postgres/master/images/demo.gif)

  ## Small example

  The following example uses PostgreSQL adapter to distribute messages:

  ```elixir
  iex(1)> channel = %Yggdrasil.Channel{name: "some_channel", adapter: :postgres}
  iex(2)> Yggdrasil.subscribe(channel)
  iex(3)> flush()
  {:Y_CONNECTED, %YggdrasilChannel{(...)}}
  ```

  and to publish a message for the subscribers:

  ```elixir
  iex(4)> Yggdrasil.publish(channel, "message")
  iex(5)> flush()
  {:Y_EVENT, %Yggdrasil.Channel{(...)}, "message"}
  ```

  When the subscriber wants to stop receiving messages, then it can unsubscribe
  from the channel:

  ```elixir
  iex(6)> Yggdrasil.unsubscribe(channel)
  iex(7)> flush()
  {:Y_DISCONNECTED, %Yggdrasil.Channel{(...)}}
  ```

  ## PostgreSQL adapter

  The PostgreSQL adapter has the following rules:
    * The `adapter` name is identified by the atom `:postgres`.
    * The channel `name` must be a string.
    * The `transformer` must encode to a string. From the `transformer`s provided
    it defaults to `:default`, but `:json` can also be used.
    * Any `backend` can be used (by default is `:default`).

  The following is a valid channel for both publishers and subscribers:

  ```elixir
  %Yggdrasil.Channel{
    name: "postgres_channel_name",
    adapter: :postgres,
    transformer: :json
  }
  ```

  It will expect valid JSONs from PostgreSQL and it will write valid JSONs in
  PostgreSQL.

  ## PostgreSQL configuration

  Uses the list of options for `Postgrex`, but the more relevant optuons are
  shown below:
    * `hostname` - PostgreSQL hostname (defaults to `"localhost"`).
    * `port` - PortgreSQL port (defaults to `5432`).
    * `username` - PostgreSQL username (defaults to `"postgres"`).
    * `password` - PostgreSQL password (defaults to `"postgres"`).
    * `database` - PostgreSQL database (defaults to `"postgres"`).

  The following shows a configuration with and without namespace:

  ```elixir
  # Without namespace
  config :yggdrasil,
    postgres: [hostname: "postgres.zero"]

  # With namespace
  config :yggdrasil, PostgresOne,
    postgres: [
      hostname: "postgres.one",
      port: 1234
    ]
  ```

  Also the options can be provided as OS environment variables. The available
  variables are:

    * `YGGDRASIL_POSTGRES_HOSTNAME` or `<NAMESPACE>_YGGDRASIL_POSTGRES_HOSTNAME`.
    * `YGGDRASIL_POSTGRES_USERNAME` or `<NAMESPACE>_YGGDRASIL_POSTGRES_USERNAME`.
    * `YGGDRASIL_POSTGRES_PORT` or `<NAMESPACE>_YGGDRASIL_POSTGRES_PORT`.
    * `YGGDRASIL_POSTGRES_PASSWORD` or `<NAMESPACE>_YGGDRASIL_POSTGRES_PASSWORD`.
    * `YGGDRASIL_POSTGRES_DATABASE` or `<NAMESPACE>_YGGDRASIL_POSTGRES_DATABASE`.

  where `<NAMESPACE>` is the snakecase of the namespace chosen e.g. for the
  namespace `PostgresTwo`, you would use `POSTGRES_TWO` as namespace in the OS
  environment variable.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Yggdrasil.Adapter.Postgres, []}, [])
    ]

    opts = [strategy: :one_for_one, name: Yggdrasil.Postgres.Supervisor]
    Supervisor.start_link(children, opts)
  end
end