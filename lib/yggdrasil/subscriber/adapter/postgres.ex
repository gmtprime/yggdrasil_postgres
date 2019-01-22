defmodule Yggdrasil.Subscriber.Adapter.Postgres do
  @moduledoc """
  Yggdrasil subscriber adapter for Postgres. The name of the channel must be a
  binary e.g:

  Subscription to channel:

  ```
  iex(2)> channel = %Yggdrasil.Channel{name: "pg_channel", adapter: :postgres}
  iex(3)> Yggdrasil.subscribe(channel)
  :ok
  iex(4)> flush()
  {:Y_CONNECTED, %Yggdrasil.Channel{name: "pg_channel", (...)}}
  ```

  Publishing message:

  ```
  iex(5)> Yggdrasil.publish(channel, "foo")
  :ok
  ```

  Subscriber receiving message:

  ```
  iex(6)> flush()
  {:Y_EVENT, %Yggdrasil.Channel{name: "pg_channel", (...)}, "foo"}
  ```

  The subscriber can also unsubscribe from the channel:

  ```
  iex(7)> Yggdrasil.unsubscribe(channel)
  :ok
  iex(8)> flush()
  {:Y_DISCONNECTED, %Yggdrasil.Channel{name: "pg_channel", (...)}}
  ```
  """
  use Yggdrasil.Subscriber.Adapter
  use Bitwise
  use Connection

  require Logger

  alias Yggdrasil.Channel
  alias Yggdrasil.Settings.Postgres, as: Settings
  alias Yggdrasil.Subscriber.Manager
  alias Yggdrasil.Subscriber.Publisher

  defstruct [:channel, :conn, :ref, :retries]
  alias __MODULE__, as: State

  ############
  # Client API

  @impl true
  def start_link(channel, options \\ [])

  def start_link(%Channel{} = channel, options) do
    arguments = %{channel: channel}
    Connection.start_link(__MODULE__, arguments, options)
  end

  ######################
  # Connection callbacks

  @impl true
  def init(%{channel: %Channel{} = channel} = arguments) do
    new_arguments = Map.put(arguments, :retries, 0)
    state = struct(State, new_arguments)
    Process.flag(:trap_exit, true)
    Logger.debug(fn -> "Started #{__MODULE__} for #{inspect(channel)}" end)
    {:connect, :init, state}
  end

  @impl true
  def connect(
        _info,
        %State{channel: %Channel{name: name} = channel} = state
      ) do
    options = postgres_options(channel)
    {:ok, conn} = Postgrex.Notifications.start_link(options)

    try do
      Postgrex.Notifications.listen(conn, name)
    catch
      _, reason ->
        backoff(reason, state)
    else
      {:ok, ref} ->
        connected(conn, ref, state)

      error ->
        backoff(error, state)
    end
  end

  ##
  # Backoff.
  defp backoff(error, %State{channel: %Channel{} = channel} = state) do
    {backoff, new_state} = calculate_backoff(state)

    Logger.warn(fn ->
      "#{__MODULE__} cannot connect to Postgres #{inspect(channel)}" <>
        " due to #{inspect(error)}. Backing off for #{inspect(backoff)} ms"
    end)

    {:backoff, backoff, new_state}
  end

  ##
  # Connected.
  defp connected(conn, ref, %State{channel: %Channel{} = channel} = state) do
    Process.monitor(conn)

    Logger.debug(fn ->
      "#{__MODULE__} connected to Postgres #{inspect(channel)}"
    end)

    new_state = %State{state | conn: conn, ref: ref, retries: 0}
    Manager.connected(channel)
    {:ok, new_state}
  end

  @impl true
  def disconnect(_info, %State{conn: nil, ref: nil} = state) do
    disconnected(state)
  end

  def disconnect(:down, %State{channel: channel} = state) do
    Manager.disconnected(channel)
    disconnect(:down, %State{state | conn: nil, ref: nil})
  end

  def disconnect(:exit, %State{channel: channel} = state) do
    Manager.disconnected(channel)
    disconnect(:exit, %State{state | conn: nil, ref: nil})
  end

  ##
  # Disconnected.
  defp disconnected(%State{channel: %Channel{} = channel} = state) do
    Logger.warn(fn ->
      "#{__MODULE__} disconnected from Postgres #{inspect(channel)}"
    end)

    backoff(:disconnected, state)
  end

  @impl true
  def handle_info(
        {:notification, _, _, _, message},
        %State{channel: channel} = state
      ) do
    Publisher.notify(channel, message)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, _, _}, %State{} = state) do
    {:disconnect, :down, state}
  end

  def handle_info({:EXIT, _, _}, %State{} = state) do
    {:disconnect, :exit, state}
  end

  def handle_info(_, %State{} = state) do
    {:noreply, state}
  end

  @impl true
  def terminate(reason, %State{conn: nil, ref: nil} = state) do
    terminated(reason, state)
  end

  def terminate(
        reason,
        %State{channel: channel, conn: conn, ref: ref} = state
      ) do
    Postgrex.Notifications.unlisten(conn, ref)
    GenServer.stop(conn)
    Manager.disconnected(channel)
    terminate(reason, %State{state | conn: nil, ref: nil})
  end

  ##
  # Terminated.
  defp terminated(:normal, %State{channel: %Channel{} = channel}) do
    Logger.debug(fn ->
      "Stopped #{__MODULE__} for #{inspect(channel)}"
    end)
  end

  defp terminated(reason, %State{channel: %Channel{} = channel}) do
    Logger.warn(fn ->
      "Stopped #{__MODULE__} for #{inspect(channel)} due to #{inspect(reason)}"
    end)
  end

  #########
  # Helpers

  @doc false
  def calculate_backoff(
        %State{channel: %Channel{namespace: namespace}, retries: retries} =
          state
      ) do
    max_retries = Settings.yggdrasil_postgres_max_retries!(namespace)
    new_retries = if retries == max_retries, do: retries, else: retries + 1

    slot_size = Settings.yggdrasil_postgres_slot_size!(namespace)
    # ms
    new_backoff = (2 <<< new_retries) * Enum.random(1..slot_size)

    new_state = %State{state | retries: new_retries}

    {new_backoff, new_state}
  end

  @doc false
  def postgres_options(%Channel{namespace: namespace}) do
    [
      hostname: Settings.yggdrasil_postgres_hostname!(namespace),
      port: Settings.yggdrasil_postgres_port!(namespace),
      username: Settings.yggdrasil_postgres_username!(namespace),
      password: Settings.yggdrasil_postgres_password!(namespace),
      database: Settings.yggdrasil_postgres_database!(namespace)
    ]
  end
end
