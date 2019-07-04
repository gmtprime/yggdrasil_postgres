# Yggdrasil for PostgreSQL

[![Build Status](https://travis-ci.org/gmtprime/yggdrasil_postgres.svg?branch=master)](https://travis-ci.org/gmtprime/yggdrasil_postgres) [![Hex pm](http://img.shields.io/hexpm/v/yggdrasil_postgres.svg?style=flat)](https://hex.pm/packages/yggdrasil_postgres) [![hex.pm downloads](https://img.shields.io/hexpm/dt/yggdrasil_postgres.svg?style=flat)](https://hex.pm/packages/yggdrasil_postgres)

`Yggdrasil` for PostgreSQL is a publisher/subscriber that:

- It's easy to use and configure.
- It's fault tolerant: recovers disconnected subscriptions.
- It has reconnection support: configurable exponential backoff.
- It has OS environment variable configuration support (useful for
[Distillery](https://github.com/bitwalker/distillery) releases).

## Small example

The following example uses PostgreSQL adapter to distribute messages e.g:

Given the following channel:

```elixir
iex> channel = [name: "pg_channel", adapter: :postgres]
```

You can:

* Subscribe to it:

  ```elixir
  iex> Yggdrasil.subscribe(channel)
  iex> flush()
  {:Y_CONNECTED, %Yggdrasil.Channel{...}}
  ```

* Publish messages to it:

  ```elixir
  iex> Yggdrasil.publish(channel, "message")
  iex> flush()
  {:Y_EVENT, %Yggdrasil.Channel{...}, "message"}
  ```

* Unsubscribe from it:

  ```elixir
  iex> Yggdrasil.unsubscribe(channel)
  iex> flush()
  {:Y_DISCONNECTED, %Yggdrasil.Channel{...}}
  ```

And additionally, you can use `Yggdrasil` behaviour to build a subscriber:

```elixir
defmodule Subscriber do
  use Yggdrasil

  def start_link do
    channel = [name: "pg_channel", adapter: :postgres]
    Yggdrasil.start_link(__MODULE__, [channel])
  end

  @impl Yggdrasil
  def handle_event(_channel, message, _) do
    IO.inspect message
    {:ok, nil}
  end
end
```

The previous `Subscriber` will print every message that comes from the
PostgreSQL channel `pg_channel`.

## PostgreSQL adapter

The PostgreSQL adapter has the following rules:

* The `adapter` name is identified by the atom `:postgres`.
* The channel `name` must be a string.
* The `transformer` must encode to a string. From the `transformer`s provided,
  it defaults to `:default`, but `:json` can also be used.
* Any `backend` can be used (by default is `:default`).

The following is an example of a valid channel for both publishers and
subscribers:

```elixir
%Yggdrasil.Channel{
  name: "pg_channel",
  adapter: :postgres,
  transformer: :json
}
```

The previous channel expects to:

- Subscribe to or publish to the channel `pg_channel`.
- The adapter is `:postgres`, so it will connect to PostgreSQL using the
  appropriate adapter.
- The transformer expects valid JSONs when decoding (consuming from a
  subscription) and `map()` or `keyword()` when encoding (publishing).

> Note: Though the struct `Yggdrasil.Channel` is used. `keyword()` and `map()`
> are also accepted as channels as long as the contain the required keys.


## PostgreSQL configuration

This adapter supports the following list of options:

Option                   | Default       | Description
:----------------------- | :------------ | :----------
`hostname`               | `"localhost"` | PostgreSQL hostname.
`port`                   | `5432`        | PostgreSQL  port.
`username`               | `"postgres"`  | PostgreSQL username.
`password`               | `"postgres"`  | PostgreSQL password.
`database`               | `"postgres"`  | PostgreSQL database.
`max_retries`            | `3`           | Amount of retries where the backoff time is incremented.
`slot_size`              | `10`          | Max amount of slots when adapters are trying to reconnect.
`subscriber_connections` | `1`           | Amount of subscriber connections.
`publisher_connections`  | `1`           | Amount of publisher connections.

> Note: Concurrency is handled by `Postgrex` subscriptions in order to reuse
> database connections.

> For more information about the available options check
> `Yggdrasil.Settings.Postgres`.

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

All the available options are also available as OS environment variables.
It's possible to even separate them by namespace e.g:

Given two namespaces, the default one and `Postgres.One`, it's possible to
load the `hostname` from the OS environment variables as follows:

- `$YGGDRASIL_POSTGRES_HOSTNAME` for the default namespace.
- `$POSTGRES_ONE_YGGDRASIL_POSTGRES_HOSTNAME` for `Postgres.One`.

In general, the namespace will go before the name of the variable.

## Installation

Using this adapter with `Yggdrasil` is a matter of adding the
available hex package to your `mix.exs` file e.g:

```elixir
def deps do
  [{:yggdrasil_postgres, "~> 5.0"}]
end
```

## Running the tests

A `docker-compose.yml` file is provided with the project. If  you don't have a
PostgreSQL server, but you do have Docker installed, then you can run:

```
$ docker-compose up --build
```

And in another shell run:

```
$ mix deps.get
$ mix test
```

## Author

Alexander de Sousa.

## License

`Yggdrasil` is released under the MIT License. See the LICENSE file for further
details.
