defmodule Yggdrasil.Postgres.Application do
  @moduledoc """
  Module that defines Yggdrasil with Postgres support.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Yggdrasil.Adapter.Postgres, []}, [])
    ]

    opts = [strategy: :one_for_one, name: Yggdrasil.Postgres.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
