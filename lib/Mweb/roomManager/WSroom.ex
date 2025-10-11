defmodule  Mweb.WSroom do
  @moduledoc """
    Modulo encargado de manejar las conexiones webSocket con el cliente
  """
  @behaviour :cowboy_websocket

  require Timing
  alias Mweb.RoomManager.RoomStore

  # Cuando un nuevo usuario se conecta a la room lo agrego
  def init(req = %{pid: ip, path_info: [roomId, userId]}, state) do
    GenServer.cast(RoomStore.getRoom(roomId), {:addPlayer, ip, userId})
    {:cowboy_websocket, req, state}
  end

  def websocket_init(status) do
    {:ok, status}
  end

  # Recibo un mensaje del usuario
  def websocket_handle({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"type" => "ping"}} -> # Para mantener la conexion abierta
        {:reply, {:text, Jason.encode!(%{type: "pong"})}, state}
      {:ok, %{"type" => "victimSelect", "roomId" => roomId, "victim" => victim}} -> # Momento que deciden la victima
        GenServer.cast(RoomStore.getRoom(roomId), {:victimSelect, victim})
        {:ok, state}
      {:ok, %{"type" => "saveSelect", "roomId" => roomId, "saved" => player}} -> # Momento que deciden el salvado
        GenServer.cast(RoomStore.getRoom(roomId), {:saveSelect, player})
        {:ok, state}
      {:ok, %{"type" => "guiltySelect", "roomId" => roomId, "guilty" => player}} -> # Se devuelve si es asesino o no
#        IO.puts("DEBUG guiltySelect player = " + player)
        isMafiaAnswer = GenServer.call(RoomStore.getRoom(roomId), {:isMafia, player})
        timestamp = Timing.get_timestamp_stage(:transicion)
        {:reply, {:text, Jason.encode!(%{type: "action", action: "guiltyAnswer", answer: isMafiaAnswer, timestamp_guilty_answer: timestamp})}, state}        
      {:ok, %{"type" => "finalVoteSelect", "roomId" => roomId, "voted" => player}} -> # Momento que deciden el salvado
        GenServer.cast(RoomStore.getRoom(roomId), {:saveSelect, player})
        {:ok, state}
      _ ->
        {:ok, state}
    end
  end

  def websocket_handle(_other, status) do
    {:ok, status}
  end

  # Cuando el usuario cierra la conexion lo borro de la room
  def terminate(_reason, req, _status) do
    [_padd, _ws, roomId, userId] = String.split(req.path, "/")

    # PROBLEMA borro por nombre => si hay nombres repetidos borro a todos los q tienen ese nombre
    GenServer.cast(RoomStore.getRoom(roomId), {:removePlayer, userId})

    :ok
  end

  def websocket_info({:msg, payload}, state) do
    {:reply, {:text, payload}, state}
  end

  def websocket_info(info, roomStore) do
    {:reply, {:text, "#{inspect(info)}"}, roomStore}
  end
end
