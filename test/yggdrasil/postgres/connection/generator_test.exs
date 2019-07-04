defmodule Yggdrasil.Postgres.Connection.GeneratorTest do
  use ExUnit.Case

  alias Yggdrasil.Postgres.Connection.Generator

  setup do
    namespace = __MODULE__
    {:ok, [namespace: namespace]}
  end

  describe "get_connection/2 for subscriber" do
    setup %{namespace: namespace} do
      {:ok, [tag: :subscriber, namespace: namespace]}
    end

    test "returns a new connection", %{tag: tag, namespace: namespace} do
      assert {:ok, conn} = Generator.get_connection(tag, namespace)
      assert is_pid(conn) and Process.alive?(conn)
    end

    test "returns the same connection when called twice",
         %{tag: tag, namespace: namespace} do
      assert {:ok, conn} = Generator.get_connection(tag, namespace)
      assert {:ok, ^conn} = Generator.get_connection(tag, namespace)
    end

    test "connection process is for notifications",
         %{tag: tag, namespace: namespace} do
      assert {:ok, conn} = Generator.get_connection(tag, namespace)
      state = :sys.get_state(conn)
      assert is_map(state)
    end

    test "returns an error when no connection is available", %{tag: tag} do
      namespace = __MODULE__.Disconnected
      config = [postgres: [hostname: "disconnected"]]
      Application.put_env(:yggdrasil, namespace, config)

      assert {:error, _} = Generator.get_connection(tag, namespace)
    end
  end

  describe "get_connection/2 for publisher" do
    setup %{namespace: namespace} do
      {:ok, [tag: :publisher, namespace: namespace]}
    end

    test "returns a new connection", %{tag: tag, namespace: namespace} do
      assert {:ok, conn} = Generator.get_connection(tag, namespace)
      assert is_pid(conn) and Process.alive?(conn)
    end

    test "returns the same connection when called twice",
         %{tag: tag, namespace: namespace} do
      assert {:ok, conn} = Generator.get_connection(tag, namespace)
      assert {:ok, ^conn} = Generator.get_connection(tag, namespace)
    end

    test "connection process is for DB connection",
         %{tag: tag, namespace: namespace} do
      assert {:ok, conn} = Generator.get_connection(tag, namespace)
      state = :sys.get_state(conn)
      assert is_tuple(state)
    end
  end
end
