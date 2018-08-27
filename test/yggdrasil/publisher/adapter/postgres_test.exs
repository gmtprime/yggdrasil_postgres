defmodule Yggdrasil.Publisher.Adapter.PostgresTest do
  use ExUnit.Case, async: true

  alias Yggdrasil.Channel
  alias Yggdrasil.Registry
  alias Yggdrasil.Publisher.Adapter

  test "publish" do
    name = "t#{UUID.uuid4() |> :erlang.phash2() |> to_string()}"
    channel = %Channel{name: name, adapter: :postgres}
    {:ok, channel} = Registry.get_full_channel(channel)
    :ok = Yggdrasil.subscribe(channel)

    assert_receive {:Y_CONNECTED, _}, 500

    assert {:ok, adapter} = Adapter.start_link(channel)
    assert :ok = Adapter.publish(adapter, channel, "message", [])
    assert_receive {:Y_EVENT, _, "message"}, 500
    assert :ok = Adapter.stop(adapter)
  end
end