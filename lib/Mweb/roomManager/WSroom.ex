defmodule  Mweb.WSroom do
  @behaviour :cowboy_websocket

  # Cuando un nuevo usuario se conecta a la room lo agrego
  def init(req = %{peer: ip, path_info: [roomId, userId]}, [roomStore]) do
    roomPid = GenServer.call(roomStore, {:getRoom, roomId})
    GenServer.cast(roomPid, {:addPlayer, ip, userId})

    {:cowboy_websocket, req, roomStore}
  end

  def websocket_init(roomStore) do
    {:ok, roomStore}
  end

  # Recibo un mensaje del usuario
  def websocket_handle({:text, msg}, roomStore) do
    case Jason.decode(msg) do
      {:ok, %{"type" => "ping"}} ->
        # Para mantener la conexion abierta
        {:reply, {:text, Jason.encode!(%{type: "pong"})}, roomStore}
      {:ok, data} ->
        IO.inspect(data, label: "Mensaje en JSON")
        {:reply, {:text, "Echo: " <> data}, roomStore}
      _ ->
        {:ok, roomStore}
    end
  end

  def websocket_handle(_other, roomStore) do
    {:ok, roomStore}
  end

  # Cuando el usuario cierra la conexion lo borro de la room
  def terminate(_reason, req, roomStore) do
    [_padd, _ws, roomId, userId] = String.split(req.path, "/")

    roomPid = GenServer.call(roomStore, {:getRoom, roomId})
    GenServer.cast(roomPid, {:removePlayer, req.peer, userId})

    :ok
  end

  def websocket_info(info, roomStore) do
    {:reply, {:text, "Server event: #{inspect(info)}"}, roomStore}
  end
end
