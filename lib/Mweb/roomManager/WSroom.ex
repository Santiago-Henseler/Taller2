defmodule  Mweb.WSroom do
  @moduledoc """
    Modulo encargado de manejar las conexiones webSocket con el cliente
  """
  @behaviour :cowboy_websocket

  alias Mweb.RoomManager.RoomStore

  # Cuando un nuevo usuario se conecta a la room lo agrego
  def init(req = %{pid: ip, path_info: [roomId, userId]}, state) do
    roomPid = RoomStore.getRoom(roomId)
    GenServer.cast(roomPid, {:addPlayer, ip, userId})

    {:cowboy_websocket, req, state}
  end

  def websocket_init(status) do
    {:ok, status}
  end

  # Recibo un mensaje del usuario
  def websocket_handle({:text, msg}, status) do
    case Jason.decode(msg) do
      {:ok, %{"type" => "ping"}} ->
        # Para mantener la conexion abierta
        {:reply, {:text, Jason.encode!(%{type: "pong"})}, status}
      {:ok, data} ->
        {:reply, {:text, "Echo: " <> data}, status}
      _ ->
        {:ok, status}
    end
  end

  def websocket_handle(_other, status) do
    {:ok, status}
  end

  # Cuando el usuario cierra la conexion lo borro de la room
  def terminate(_reason, req, _status) do
    [_padd, _ws, roomId, userId] = String.split(req.path, "/")

    # PROBLEMA no puedo obtener el PID para luego borrarlo del room
    roomPid = RoomStore.getRoom(roomId)
    GenServer.cast(roomPid, {:removePlayer, req.peer, userId})

    :ok
  end

  def websocket_info(info, roomStore) do
    {:reply, {:text, "#{inspect(info)}"}, roomStore}
  end
end
