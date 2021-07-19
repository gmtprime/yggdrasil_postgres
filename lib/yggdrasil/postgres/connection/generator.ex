defmodule Yggdrasil.Postgres.Connection.Generator do
  @moduledoc """
  This module defines a supervisor for creating connection pools on demand.
  """
  use DynamicSupervisor

  alias Yggdrasil.Postgres.Connection
  alias Yggdrasil.Postgres.Connection.Pool

  @doc """
  Starts a connection pool generator.
  """
  @spec start_link() :: Supervisor.on_start()
  @spec start_link([
          DynamicSupervisor.option() | DynamicSupervisor.init_option()
        ]) ::
          Supervisor.on_start()
  def start_link(options \\ []) do
    DynamicSupervisor.start_link(__MODULE__, nil, options)
  end

  @doc """
  Stops a connection pool `generator`. Optionally, it receives a `reason`
  (defaults to `:normal`) and a `timeout` (default to `:infinity`).
  """
  @spec stop(Supervisor.supervisor()) :: :ok
  @spec stop(Supervisor.supervisor(), term()) :: :ok
  @spec stop(Supervisor.supervisor(), term(), :infinity | non_neg_integer()) ::
          :ok
  defdelegate stop(generator, reason \\ :normal, timeout \\ :infinity),
    to: DynamicSupervisor

  @doc """
  Gets a connection for a `tag` and a `namespace`.
  """
  @spec get_connection(Connection.tag(), Connection.namespace()) ::
          {:ok, pid()} | {:error, term()}
  def get_connection(tag, namespace)

  def get_connection(tag, namespace) do
    case connect(__MODULE__, tag, namespace) do
      {:ok, _} ->
        Pool.get_connection(tag, namespace)

      {:error, {:already_started, _}} ->
        Pool.get_connection(tag, namespace)

      error ->
        error
    end
  end

  ############################
  # DynamicSupervisor callback

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  #########
  # Helpers

  @doc false
  @spec connect(
          Supervisor.supervisor(),
          Connection.tag(),
          Connection.namespace()
        ) :: DynamicSupervisor.on_start_child()
  def connect(generator, tag, namespace)

  def connect(generator, tag, namespace) do
    name = gen_pool_name(tag, namespace)

    case ExReg.whereis_name(name) do
      :undefined ->
        specs = gen_pool_specs(name, tag, namespace)
        DynamicSupervisor.start_child(generator, specs)

      pid when is_pid(pid) ->
        {:ok, pid}
    end
  end

  ##
  # Generates the pool name.
  defp gen_pool_name(tag, namespace) do
    {__MODULE__, tag, namespace}
  end

  ##
  # Generates the pool spec.
  defp gen_pool_specs(name, tag, namespace) do
    via_tuple = ExReg.local(name)

    %{
      id: via_tuple,
      type: :supervisor,
      restart: :transient,
      start: {Pool, :start_link, [tag, namespace, [name: via_tuple]]}
    }
  end
end
