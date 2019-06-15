defmodule Yggdrasil.Postgres.ConnectionTest do
  use ExUnit.Case

  alias Yggdrasil.Postgres.Connection

  describe "when PostgreSQL is unreachable" do
    setup do
      tag = :subscriber
      namespace = __MODULE__.Unreachable
      config = [postgres: [hostname: "unreachable"]]
      Application.put_env(:yggdrasil, namespace, config)

      assert :ok = Connection.subscribe(tag, namespace)
      assert_receive {:Y_CONNECTED, _}

      config = %{tag: tag, namespace: namespace}
      assert {:ok, conn} = Connection.start_link(config)
      assert_receive {:Y_EVENT, _, :backing_off}, 5000
      {:ok, [tag: tag, namespace: namespace, conn: conn]}
    end

    test "connection in state is nil", %{conn: conn} do
      assert %Connection{conn: nil} = :sys.get_state(conn)
    end

    test "tag is set", %{tag: tag, conn: conn} do
      assert %Connection{tag: ^tag} = :sys.get_state(conn)
    end

    test "namespace is set", %{namespace: namespace, conn: conn} do
      assert %Connection{namespace: ^namespace} = :sys.get_state(conn)
    end

    test "backoff is greater than zero", %{conn: conn} do
      %Connection{backoff: backoff} = :sys.get_state(conn)
      assert backoff > 0
    end

    test "retries are greater than zero", %{conn: conn} do
      %Connection{retries: retries} = :sys.get_state(conn)
      assert retries > 0
    end
  end

  describe "when PostgreSQL is reachable and it's subscriber" do
    setup do
      config = %{tag: :subscriber, namespace: nil}
      assert {:ok, conn} = Connection.start_link(config)

      {:ok, [conn: conn]}
    end

    test "backoff is zero", %{conn: conn} do
      assert %Connection{backoff: 0} = :sys.get_state(conn)
    end

    test "retries are zero", %{conn: conn} do
      assert %Connection{retries: 0} = :sys.get_state(conn)
    end
  end

  describe "when PostgreSQL is reachable and it's a publisher" do
    setup do
      config = %{tag: :publisher, namespace: nil}
      assert {:ok, conn} = Connection.start_link(config)

      {:ok, [conn: conn]}
    end

    test "backoff is zero", %{conn: conn} do
      assert %Connection{backoff: 0} = :sys.get_state(conn)
    end

    test "retries are zero", %{conn: conn} do
      assert %Connection{retries: 0} = :sys.get_state(conn)
    end
  end

  describe "get/1" do
    setup do
      namespace = __MODULE__.Unreachable
      config = [postgres: [hostname: "unreachable"]]
      Application.put_env(:yggdrasil, namespace, config)

      {:ok, [namespace: namespace]}
    end

    test "when unreachable, cannot get connection", %{namespace: namespace} do
      config = %{tag: :subscriber, namespace: namespace}
      assert {:ok, conn} = Connection.start_link(config)
      assert {:error, _} = Connection.get(conn)
    end

    test "when reachable, can get connection" do
      config = %{tag: :subscriber, namespace: nil}
      assert {:ok, conn} = Connection.start_link(config)
      assert {:ok, conn} = Connection.get(conn)
      assert is_pid(conn) and Process.alive?(conn)
    end
  end

  describe "postgres_options/1" do
    test "all parameters are defined" do
      parameters = Connection.postgres_options(%Connection{})
      expected = [:hostname, :port, :username, :password, :database]
      assert [] == expected -- Keyword.keys(parameters)
      assert [] == Keyword.keys(parameters) -- expected
    end
  end

  describe "connect/1" do
    setup do
      namespace = __MODULE__.Unreachable
      config = [postgres: [hostname: "unreachable"]]
      Application.put_env(:yggdrasil, namespace, config)

      {:ok, [namespace: namespace]}
    end

    test "when is unreachable and subscriber, errors",
         %{namespace: namespace} do
      state = %Connection{tag: :subscriber, namespace: namespace}
      assert {:error, _} = Connection.connect(state)
    end

    test "when reachable, returns new state with connection" do
      assert {:ok, state} = Connection.connect(%Connection{})
      assert Process.alive?(state.conn)
    end
  end

  describe "backoff/2" do
    test "calculates new backoff" do
      assert state = Connection.backoff(:error, %Connection{})
      assert 20_000 >= state.backoff and state.backoff >= 2_000
    end

    test "calculates new retries" do
      assert state = Connection.backoff(:error, %Connection{})
      assert state.retries == 1
    end
  end

  describe "disconnect/2" do
    setup do
      {:ok, state} = Connection.connect(%Connection{})
      {:ok, [state: state]}
    end

    test "sets the connection to nil", %{state: state} do
      assert %Connection{conn: nil} = Connection.disconnect(:error, state)
    end

    test "terminates the connection", %{state: %{conn: conn} = state} do
      Process.monitor(conn)
      assert %Connection{conn: nil} = Connection.disconnect(:error, state)
      assert_receive {:DOWN, _, _, _, _}
    end
  end
end
