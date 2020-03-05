defmodule Yggdrasil.Postgres.Connection.Pool do
  @moduledoc """
  PostgreSQL listener connection pool.
  """
  use Supervisor

  alias Yggdrasil.Postgres.Connection
  alias Yggdrasil.Settings.Postgres, as: Settings

  ############
  # Public API

  @doc """
  Starts a connection pool using an initial `tag` and `namespace`. Optionally,
  it receives some `Supervisor` `options`.
  """
  @spec start_link(Connection.tag(), Connection.namespace()) ::
          Supervisor.on_start()
  @spec start_link(
          Connection.tag(),
          Connection.namespace(),
          [Supervisor.option() | Supervisor.init_option()]
        ) :: Supervisor.on_start()
  def start_link(tag, namespace, options \\ [])

  def start_link(tag, namespace, options) do
    Supervisor.start_link(__MODULE__, [tag, namespace], options)
  end

  @doc """
  Stops a PostgreSQL listener connection `pool`. Optionally, it receives a stop
  `reason` (defaults to `:normal`) and timeout (defaults to `:infinity`).
  """
  @spec stop(Supervisor.supervisor()) :: :ok
  @spec stop(Supervisor.supervisor(), term()) :: :ok
  @spec stop(Supervisor.supervisor(), term(), :infinity | non_neg_integer()) ::
          :ok
  defdelegate stop(pool, reason \\ :normal, timeout \\ :infinity),
    to: Supervisor

  @doc """
  Gets a connection for a `tag` and `namespace`.
  """
  @spec get_connection(Connection.tag(), Connection.namespace()) ::
          {:ok, pid()} | {:error, term()}
  def get_connection(tag, namespace)

  def get_connection(tag, namespace) do
    name = gen_pool_name(tag, namespace)

    :poolboy.transaction(name, &Connection.get(&1))
  end

  #####################
  # Supervisor callback

  @impl true
  def init([tag, namespace]) do
    name = gen_pool_name(tag, namespace)
    size = get_pool_size(tag, namespace)

    pool_args = [
      name: name,
      worker_module: Connection,
      size: size,
      max_overflow: size
    ]

    children = [
      :poolboy.child_spec(name, pool_args, tag: tag, namespace: namespace)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  #########
  # Helpers

  ##
  # Generates pool name.
  defp gen_pool_name(tag, namespace) do
    ExReg.local({__MODULE__, tag, namespace})
  end

  ##
  # Gets pool size depending on the tag and namespace.
  @spec get_pool_size(Connection.tag(), Connection.namespace()) :: integer()
  defp get_pool_size(tag, namespace)

  defp get_pool_size(:subscriber, namespace) do
    {:ok, size} = Settings.subscriber_connections(namespace)
    size
  end

  defp get_pool_size(:publisher, namespace) do
    {:ok, size} = Settings.publisher_connections(namespace)
    size
  end
end
