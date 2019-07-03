defmodule Yggdrasil.Publisher.Adapter.Postgres do
  @moduledoc """
  Yggdrasil publisher adapter for Postgres. The name of the channel must be a
  binary e.g:

  Subscription to channel:

  ```
  iex(1)> channel = [name: "pg_channel", adapter: :postgres]
  iex(2)> Yggdrasil.subscribe(channel)
  :ok
  iex(3)> flush()
  {:Y_CONNECTED, %Yggdrasil.Channel{name: "pg_channel", (...)}}
  ```

  Publishing message:

  ```
  iex(4)> Yggdrasil.publish(channel, "foo")
  :ok
  ```

  Subscriber receiving message:

  ```
  iex(5)> flush()
  {:Y_EVENT, %Yggdrasil.Channel{name: "pg_channel", (...)}, "foo"}
  ```

  The subscriber can also unsubscribe from the channel:

  ```
  iex(6)> Yggdrasil.unsubscribe(channel)
  :ok
  iex(7)> flush()
  {:Y_DISCONNECTED, %Yggdrasil.Channel{name: "pg_channel", (...)}}
  ```
  """
  use Yggdrasil.Publisher.Adapter
  use GenServer

  require Logger

  alias Yggdrasil.Channel
  alias Yggdrasil.Postgres.Connection.Generator, as: ConnectionGen
  alias Yggdrasil.Transformer

  ############
  # Client API

  @doc """
  Starts a Postgres publisher with a `namespace`. Additianally you can add
  `GenServer` `options`.
  """
  @spec start_link(term()) :: GenServer.on_start()
  @spec start_link(term(), GenServer.options()) :: GenServer.on_start()
  @impl Yggdrasil.Publisher.Adapter
  def start_link(namespace, options \\ [])

  def start_link(namespace, options) do
    GenServer.start_link(__MODULE__, namespace, options)
  end

  @doc """
  Stops a Postgres `publisher`. Optionally, receives a stop `reason` (defaults
  to `:normal`) and a `timeout` in milliseconds (defaults to `:infinity`).
  """
  @spec stop(GenServer.name()) :: :ok
  @spec stop(GenServer.name(), term()) :: :ok
  @spec stop(GenServer.name(), term(), non_neg_integer() | :infinity) :: :ok
  defdelegate stop(publisher, reason \\ :normal, timeout \\ :infinity),
    to: GenServer

  @doc """
  Publishes a `message` in a `channel` using a `publisher` and optional and
  unused `options`.
  """
  @spec publish(GenServer.name(), Channel.t(), term()) ::
          :ok | {:error, term()}
  @spec publish(GenServer.name(), Channel.t(), term(), Keyword.t()) ::
          :ok | {:error, term()}
  @impl Yggdrasil.Publisher.Adapter
  def publish(publisher, channel, message, options \\ [])

  def publish(publisher, %Channel{} = channel, message, _options) do
    GenServer.call(publisher, {:publish, channel, message})
  end

  ####################
  # GenServer callback

  @impl GenServer
  def init(namespace) do
    {:ok, namespace}
  end

  @impl GenServer
  def handle_call({:publish, %Channel{} = channel, message}, _, namespace) do
    result = send_message(namespace, channel, message)
    {:reply, result, namespace}
  end

  #########
  # Helpers

  ##
  # Sends a messages to PostgreSQL.
  defp send_message(namespace, %Channel{name: name} = channel, message) do
    with {:ok, encoded} <- Transformer.encode(channel, message),
         {:ok, conn} <- ConnectionGen.get_connection(:publisher, namespace),
         {:ok, _} <- Postgrex.query(conn, "NOTIFY #{name}, '#{encoded}'", []) do
      :ok
    end
  end
end
