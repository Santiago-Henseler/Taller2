defmodule MWeb.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    {:ok, pid} = GenServer.start(Mweb.RoomManager.RoomStore, "")

    dispatch = [
      {:_,
       [
         {"/ws/[...]", Mweb.WSroom, [pid]},
         {:_, Plug.Cowboy.Handler, {Mweb.Ruta, [pid]}}
       ]}
    ]

    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: Mweb.Ruta,
       options: [port: 4000, dispatch: dispatch]}
    ]

    opts = [strategy: :one_for_one, name: Mweb.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
