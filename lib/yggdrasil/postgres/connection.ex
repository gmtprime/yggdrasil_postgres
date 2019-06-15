defmodule Yggdrasil.Postgres.Connection do
  @moduledoc """
  This module defines a PostgreSQL connection.
  """
  use GenServer
  use Bitwise

  require Logger

  alias Yggdrasil.Settings.Postgres, as: Settings

  @typedoc """
  Connection types.
  """
  @type tag :: :subscriber | :publisher

  @typedoc """
  Namespace for the connection.
  """
  @type namespace :: nil | atom()

  @doc false
  defstruct namespace: nil,
            tag: :subscriber,
            conn: nil,
            retries: 0,
            backoff: 0

  alias __MODULE__, as: State

  @typedoc false
  @type t :: %State{
    namespace: namespace :: namespace(),
    tag: tag :: tag(),
    conn: connection :: pid(),
    retries: retries :: non_neg_integer(),
    backoff: backoff :: non_neg_integer()
  }

  ############
  # Public API

  @doc """
  Starts a PostgreSQL connection with a `tag` and `namespace` for the
  configuration. Additionally, it receives `GenServer` `options`.
  """
  @spec start_link(map()) :: GenServer.on_start()
  @spec start_link(map(), GenServer.options()) :: GenServer.on_start()
  def start_link(config, options \\ [])

  def start_link(%{tag: tag, namespace: namespace}, options) do
    GenServer.start_link(__MODULE__, [tag, namespace], options)
  end

  @doc """
  Stops a PostgreSQL `connection`. Optionally, it receives a stop `reason`
  (defaults to `:normal`) and a timeout in milliseconds (defaults to
  `:infinity`).
  """
  @spec stop(GenServer.name()) :: :ok
  @spec stop(GenServer.name(), term()) :: :ok
  @spec stop(GenServer.name(), term(), :infinity | non_neg_integer()) :: :ok
  defdelegate stop(connection, reason \\ :normal, timeout \\ :infinity),
    to: GenServer

  @doc """
  Gets connection from a `connection` process.
  """
  @spec get(GenServer.name()) :: {:ok, term()} | {:error, term()}
  def get(connection)

  def get(connection) do
    GenServer.call(connection, :get)
  end

  @doc """
  Subscribes to the connection given a `tag` and `namespace`.
  """
  @spec subscribe(tag(), namespace()) :: :ok
  def subscribe(tag, namespace)

  def subscribe(tag, namespace) do
    Yggdrasil.subscribe(name: {__MODULE__, tag, namespace})
  end

  #####################
  # GenServer callbacks

  @impl true
  def init([tag, namespace]) do
    Process.flag(:trap_exit, true)
    state = %State{tag: tag, namespace: namespace}
    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, %State{} = state) do
    with {:ok, new_state} <- connect(state) do
      {:noreply, new_state}
    else
      error ->
        {:noreply, state, {:continue, {:backoff, error}}}
    end
  end

  def handle_continue({:backoff, error}, %State{} = state) do
    new_state = backoff(error, state)
    {:noreply, new_state}
  end

  def handle_continue({:disconnect, reason}, %State{} = state)
      when reason != :normal do
    new_state = disconnect(reason, state)
    {:noreply, new_state, {:continue, {:backoff, reason}}}
  end

  @impl true
  def handle_info({:timeout, continue}, %State{} = state) do
    {:noreply, state, continue}
  end

  def handle_info({:DOWN, _, :process, _, reason}, %State{} = state)
      when reason != :normal do
    {:noreply, state, {:continue, {:disconnect, reason}}}
  end

  def handle_info({:EXIT, _, reason}, %State{} = state)
      when reason != :normal do
    {:noreply, state, {:continue, {:disconnect, reason}}}
  end

  def handle_info(_, %State{} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:get, _from, %State{conn: nil} = state) do
    {:reply, {:error, "Not connected"}, state}
  end

  def handle_call(:get, _from, %State{conn: conn} = state) do
    {:reply, {:ok, conn}, state}
  end

  @impl true
  def terminate(:normal, %State{} = state) do
    disconnect(:normal, state)
    :ok
  end

  def terminate(reason, %State{} = state) do
    disconnect(reason, state)
    :ok
  end

  ############################
  # Connection related helpers

  @doc false
  @spec connect(t()) :: {:ok, t()} | {:error, term()}
  def connect(state)

  def connect(%State{tag: tag, namespace: namespace} = initial_state) do
    module = get_module(initial_state)
    options = postgres_options(initial_state)

    try do
      with {:ok, conn} <- module.start_link(options) do
        _ = Process.monitor(conn)
        state = %State{tag: tag, namespace: namespace, conn: conn}
        connected(state)
        {:ok, state}
      end
    catch
      _, reason ->
        {:error, reason}
    end
  end

  @doc false
  @spec get_module(t()) :: module()
  def get_module(state)

  def get_module(%State{tag: :subscriber}), do: Postgrex.Notifications
  def get_module(%State{tag: :publisher}), do: Postgrex

  @doc false
  @spec postgres_options(t()) :: Keyword.t()
  def postgres_options(%State{namespace: namespace}) do
    [
      hostname: Settings.hostname!(namespace),
      port: Settings.port!(namespace),
      username: Settings.username!(namespace),
      password: Settings.password!(namespace),
      database: Settings.database!(namespace)
    ]
  end

  @doc false
  @spec backoff(term(), t()) :: t()
  def backoff(error, state)

  def backoff(error, %State{namespace: namespace, retries: retries} = state) do
    max_retries = Settings.max_retries!(namespace)
    slot_size = Settings.slot_size!(namespace)

    new_backoff = (2 <<< retries) * Enum.random(1..slot_size) * 1000
    Process.send_after(self(), {:timeout, {:continue, :connect}}, new_backoff)

    new_retries = if retries == max_retries, do: retries, else: retries + 1
    new_state = %State{state | retries: new_retries, backoff: new_backoff}
    backing_off(error, new_state)
    new_state
  end

  @doc false
  @spec disconnect(term(), t()) :: t()
  def disconnect(reason, state)

  def disconnect(reason, %State{conn: nil} = state) do
    disconnected(reason, state)
    state
  end

  def disconnect(reason, %State{conn: pid} = state) do
    if is_pid(pid) and Process.alive?(pid), do: :ok = GenServer.stop(pid)
    new_state = %State{state | conn: nil}
    disconnected(reason, new_state)
    new_state
  end

  #########################
  # Logging related helpers

  ##
  # Sends a notification.
  defp send_notification(%State{tag: tag, namespace: namespace}, message) do
    Yggdrasil.publish([name: {__MODULE__, tag, namespace}], message)
  end

  ##
  # Shows a messages for successful connection.
  defp connected(state)

  defp connected(%State{namespace: nil} = state) do
    send_notification(state, :connected)
    Logger.debug("#{__MODULE__} connected to PostgreSQL")
  end

  defp connected(%State{namespace: namespace} = state) do
    send_notification(state, :connected)
    Logger.debug(
      "#{__MODULE__} connected to PostgreSQL using namespace #{namespace}"
    )
  end

  ##
  # Shows a message when backing off.
  defp backing_off(error, state)

  defp backing_off(
         error,
         %State{
           namespace: nil,
           retries: retries,
           backoff: backoff
         } = state
       ) do
    send_notification(state, :backing_off)

    Logger.warn(
      "#{__MODULE__} cannot connected to PostgreSQL" <>
        " with error #{inspect(error)}" <>
        " #{inspect(retries: retries, backoff: backoff)}"
    )
  end

  defp backing_off(
         error,
         %State{
           namespace: namespace,
           retries: retries,
           backoff: backoff
         } = state
       ) do
    send_notification(state, :backing_off)

    Logger.warn(
      "#{__MODULE__} cannot connected to PostgreSQL using #{namespace}" <>
        " with error #{inspect(error)}" <>
        " #{inspect(retries: retries, backoff: backoff)}"
    )
  end

  ##
  # Shows a message on disconnection.
  defp disconnected(reason, state)

  defp disconnected(:normal, %State{namespace: nil} = state) do
    send_notification(state, :disconnected)
    Logger.debug("#{__MODULE__} disconnected from PostgreSQL")
  end

  defp disconnected(:normal, %State{namespace: namespace} = state) do
    send_notification(state, :disconnected)

    Logger.debug(
      "#{__MODULE__} disconnected from PostgreSQL using namespace #{namespace}"
    )
  end

  defp disconnected(reason, %State{namespace: nil} = state) do
    send_notification(state, :disconnected)
    Logger.warn(
      "#{__MODULE__} disconnected from PostgreSQL due to " <>
        "#{inspect(reason)}"
    )
  end

  defp disconnected(reason, %State{namespace: namespace} = state) do
    send_notification(state, :disconnected)

    Logger.warn(
      "#{__MODULE__} disconnected from PostgreSQL " <>
        "using namespace #{namespace} due to #{inspect(reason)}"
    )
  end
end
