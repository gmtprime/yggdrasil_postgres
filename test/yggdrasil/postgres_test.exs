defmodule Yggdrasil.PostgresTest do
  use ExUnit.Case

  describe "pub/sub" do
    test "API test" do
      channel = [name: "postgres_test", adapter: :postgres]

      assert :ok = Yggdrasil.subscribe(channel)
      assert_receive {:Y_CONNECTED, _}, 1_000

      assert :ok = Yggdrasil.publish(channel, "message")
      assert_receive {:Y_EVENT, _, "message"}, 1_000

      assert :ok = Yggdrasil.unsubscribe(channel)
      assert_receive {:Y_DISCONNECTED, _}, 1_000
    end
  end
end
