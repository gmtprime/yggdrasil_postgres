defmodule Yggdrasil.Subscriber.Adapter.PostgresTest do
  use ExUnit.Case, async: true

  alias Yggdrasil.Channel
  alias Yggdrasil.Registry
  alias Yggdrasil.Backend
  alias Yggdrasil.Subscriber.Publisher
  alias Yggdrasil.Subscriber.Adapter
  alias Yggdrasil.Subscriber.Adapter.Postgres

  test "distribute message" do
    name = "channel#{UUID.uuid4() |> :erlang.phash2() |> to_string()}"
    channel = %Channel{name: name, adapter: :postgres, namespace: PostgresTest}
    {:ok, channel} = Registry.get_full_channel(channel)

    Backend.subscribe(channel)
    assert {:ok, publisher} = Publisher.start_link(channel)

    assert {:ok, adapter} = Adapter.start_link(channel, publisher)
    assert_receive {:Y_CONNECTED, _}, 500

    options = Postgres.postgres_options(channel)
    {:ok, conn} = Postgrex.start_link(options)
    {:ok, _} = Postgrex.query(conn, "NOTIFY #{name}, 'message'", [])
    GenServer.stop(conn)

    assert_receive {:Y_EVENT, _, "message"}, 500

    assert :ok = Adapter.stop(adapter)
    assert_receive {:Y_DISCONNECTED, _}, 500
  end
end
