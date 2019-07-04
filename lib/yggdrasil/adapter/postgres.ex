defmodule Yggdrasil.Adapter.Postgres do
  @moduledoc """
  Yggdrasil adapter for PostgreSQL. The name of the channel must be a string
  e.g:

  Subscription to channel:

  ```
  iex(2)> channel = %Yggdrasil.Channel{
  iex(2)>   name: "my_channel",
  iex(2)>   adapter: :postgres
  iex(2)> }
  iex(3)> Yggdrasil.subscribe(channel)
  :ok
  iex(4)> flush()
  {:Y_CONNECTED, %Yggdrasil.Channel{name: "my_channel", (...)}}
  ```

  Publishing message:

  ```
  iex(5)> Yggdrasil.publish(channel, "foo")
  :ok
  ```

  Subscriber receiving message:

  ```
  iex(6)> flush()
  {:Y_EVENT, %Yggdrasil.Channel{name: "my_channel", (...)}, "foo"}
  ```

  The subscriber can also unsubscribe from the channel:

  ```
  iex(7)> Yggdrasil.unsubscribe(channel)
  :ok
  iex(8)> flush()
  {:Y_DISCONNECTED, %Yggdrasil.Channel{name: "my_channel", (...)}}
  ```
  """
  use Yggdrasil.Adapter, name: :postgres
end
