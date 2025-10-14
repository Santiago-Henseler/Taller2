defmodule MWeb.Application do
  @moduledoc false

  use Application

  alias Mweb.RoomManager.RoomStore

  @impl true
  def start(_type, _args) do

    GenServer.start_link(RoomStore, "", name: RoomStore)

    dispatch = [
      {:_,
       [
         {"/ws/[...]", Mweb.WSroom, []},
         {:_, Plug.Cowboy.Handler, {Mweb.Ruta, []}}
       ]}
    ]

    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: Mweb.Ruta,
       options: [port: 4000, dispatch: dispatch]},
    ]

    opts = [strategy: :one_for_one, name: Mweb.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
