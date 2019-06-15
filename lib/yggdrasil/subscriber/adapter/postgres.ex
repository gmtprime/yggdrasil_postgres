defmodule Yggdrasil.Subscriber.Adapter.Postgres do
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
  use Yggdrasil.Subscriber.Adapter
  use Bitwise
  use GenServer

  require Logger

  alias Yggdrasil.Channel
  alias Yggdrasil.Postgres.Connection
  alias Yggdrasil.Postgres.Connection.Generator, as: ConnectionGen
  alias Yggdrasil.Subscriber.Publisher
  alias Yggdrasil.Subscriber.Manager

  defstruct [:channel, :conn, :ref]
  alias __MODULE__, as: State

  @typedoc false
  @type t :: %State{
    channel: channel :: Channel.t(),
    conn: conn :: pid(),
    ref: ref :: reference()
  }

  ############
  # Client API

  @impl true
  def start_link(channel, options \\ [])

  def start_link(%Channel{} = channel, options) do
    GenServer.start_link(__MODULE__, channel, options)
  end

  #####################
  # GenServer callbacks

  @impl GenServer
  def init(%Channel{} = channel) do
    state = %State{channel: channel}
    {:ok, state, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, %State{channel: %Channel{namespace: namespace}} = state) do
    Connection.subscribe(:subscriber, namespace)
    {:noreply, state}
  end

  def handle_continue(:connect, %State{} = state) do
    with {:ok, new_state} <- connect(state) do
      {:noreply, new_state}
    else
      error ->
        {:noreply, state, {:continue, {:backoff, error}}}
    end
  end

  def handle_continue({:backoff, error}, %State{} = state) do
    backing_off(error, state)
    {:noreply, state}
  end

  def handle_continue({:disconnect, _}, %State{conn: nil} = state) do
    {:noreply, state}
  end

  def handle_continue({:disconnect, reason}, %State{} = state) do
    new_state = disconnect(reason, state)
    {:noreply, new_state, {:continue, {:backoff, reason}}}
  end

  @impl GenServer
  def handle_info({:Y_CONNECTED, _}, %State{conn: nil} = state) do
    {:noreply, state, {:continue, :connect}}
  end

  def handle_info({:Y_EVENT, _, :connected}, %State{conn: nil} = state) do
    {:noreply, state, {:continue, :connect}}
  end

  def handle_info(
        {:Y_EVENT, _, :disconnected},
        %State{conn: conn} = state
      )
      when not is_nil(conn) do
    {:noreply, state, {:continue, {:disconnect, "Connection down"}}}
  end

  def handle_info(
        {:Y_DISCONNECTED, _},
        %State{conn: conn} = state
      )
      when not is_nil(conn) do
    {:noreply, state, {:continue, {:disconnect, "Yggdrasil failure"}}}
  end

  def handle_info(
        {:notification, _, _, _, message},
        %State{channel: channel} = state
      ) do
    Publisher.notify(channel, message)
    {:noreply, state}
  end

  def handle_info(
        {:DOWN, _, _, pid, reason},
        %State{conn: pid} = state
      ) do
    {:noreply, state, {:continue, {:disconnect, reason}}}
  end

  def handle_info({:EXIT, reason, pid}, %State{conn: pid} = state) do
    {:noreply, state, {:continue, {:disconnect, reason}}}
  end

  def handle_info(_, %State{} = state) do
    {:noreply, state}
  end

  @impl true
  def terminate(reason, %State{conn: nil} = state) do
    terminated(reason, state)
  end

  def terminate(reason, %State{channel: %Channel{} = channel} = state) do
    Manager.disconnected(channel)
    terminated(reason, state)
  end

  #########
  # Helpers

  # Connects to a channel for subscription
  @doc false
  @spec connect(t()) :: {:ok, t()} | {:error, term()}
  def connect(state)

  def connect(
        %State{
          channel: %Channel{name: name, namespace: namespace} = channel
        } = state
      ) do
    with {:ok, conn} <- ConnectionGen.get_connection(:subscriber, namespace),
         {:ok, ref} <- Postgrex.Notifications.listen(conn, name) do
      Process.monitor(conn)
      Manager.connected(channel)
      new_state = %State{state | conn: conn, ref: ref}
      connected(new_state)
      {:ok, new_state}
    end
  catch
    _, reason ->
      {:error, reason}
  end

  @doc false
  @spec disconnect(term(), t()) :: t()
  def disconnect(error, state)

  def disconnect(_error, %State{conn: nil} = state) do
    state
  end

  def disconnect(error, %State{channel: %Channel{} = channel} = state) do
    Manager.disconnected(channel)
    disconnected(error, state)
    %State{state | conn: nil, ref: nil}
  end

  #################
  # Logging helpers

  # Shows connection message.
  defp connected(%State{channel: channel}) do
    Logger.info("#{__MODULE__} subscribed to #{inspect(channel)}")
    :ok
  end

  # Shows error when connecting.
  defp backing_off(error, %State{channel: channel}) do
    Logger.warn(
      "#{__MODULE__} cannot subscribe to #{inspect(channel)}" <>
        " due to #{inspect(error)}"
    )

    :ok
  end

  # Shows disconnection message.
  defp disconnected(error, %State{channel: %Channel{} = channel}) do
    Logger.warn(
      "#{__MODULE__} unsubscribed from #{inspect(channel)}" <>
        " due to #{inspect(error)}"
    )

    :ok
  end

  @doc false
  defp terminated(:normal, %State{channel: %Channel{} = channel}) do
    Logger.debug("#{__MODULE__} stopped for #{inspect(channel)}")
  end

  defp terminated(reason, %State{channel: %Channel{} = channel}) do
    Logger.warn(
      "#{__MODULE__} stopped for #{inspect(channel)} due to #{inspect(reason)}"
    )
  end
end
