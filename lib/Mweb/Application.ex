defmodule MWeb.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(plug: Mweb.Ruta, scheme: :http),
    ]

    opts = [strategy: :one_for_one, name: MWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
