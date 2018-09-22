# PostgreSQL adapter for Yggdrasil

[![Build Status](https://travis-ci.org/gmtprime/yggdrasil_postgres.svg?branch=master)](https://travis-ci.org/gmtprime/yggdrasil_postgres) [![Hex pm](http://img.shields.io/hexpm/v/yggdrasil_postgres.svg?style=flat)](https://hex.pm/packages/yggdrasil_postgres) [![hex.pm downloads](https://img.shields.io/hexpm/dt/yggdrasil_postgres.svg?style=flat)](https://hex.pm/packages/yggdrasil_postgres)

This project is a PostgreSQL adapter for `Yggdrasil` publisher/subscriber.

## Small example

The following example uses PostgreSQL adapter to distribute messages:

```elixir
iex(1)> channel = %Yggdrasil.Channel{name: "some_channel", adapter: :postgres}
iex(2)> Yggdrasil.subscribe(channel)
iex(3)> flush()
{:Y_CONNECTED, %Yggdrasil.Channel{(...)}}
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

The following is an example of a valid channel for both publishers and
subscribers:

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

## Installation

Using this PostgreSQL adapter with `Yggdrasil` is a matter of adding the
available hex package to your `mix.exs` file e.g:

```elixir
def deps do
  [{:yggdrasil_postgres, "~> 4.1"}]
end
```

## Running the tests

A `docker-compose.yml` file is provided with the project. If  you don't have a
PostgreSQL database, but you do have Docker installed, then just do:

```
$ docker-compose up --build
```

And in another shell run:

```
$ mix deps.get
$ mix test
```

## Relevant projects used

  * [`Postgrex`](https://github.com/elixir-ecto/postgrex): PostgreSQL pubsub.
  * [`Connection`](https://github.com/fishcakez/connection): wrapper over
  `GenServer` to handle connections.

## Author

Alexander de Sousa.

## License

`Yggdrasil` is released under the MIT License. See the LICENSE file for further
details.
