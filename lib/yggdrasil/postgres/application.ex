defmodule Yggdrasil.Postgres.Application do
  @moduledoc false
  use Application

  alias Yggdrasil.Adapter.Postgres
  alias Yggdrasil.Postgres.Connection.Generator, as: ConnectionGen

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec({ConnectionGen, [name: ConnectionGen]},
        type: :supervisor
      ),
      Supervisor.child_spec({Postgres, []}, [])
    ]

    opts = [strategy: :one_for_one, name: Yggdrasil.Postgres.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
