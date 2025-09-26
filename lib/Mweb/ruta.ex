defmodule Mweb.Ruta do
  import Plug.Conn

  def init(roomStore) do
    roomStore
  end

  # Endpoint para chequear si se puede unir a una room
  def call(conn = %{method: "POST", path_info: [roomId, "joinRoom"]}, [roomStore]) do
    roomPid = GenServer.call(roomStore, {:getRoom, roomId})

    if roomPid != nil do
      if GenServer.call(roomPid, {:canJoin}) do
        send_whit_cors(conn, 201, roomId)
      else
        send_whit_cors(conn, 404, "Room is full")
      end
    else
      send_whit_cors(conn, 404, "Room not found")
    end

  end

  # Endpoint para crear nuevas rooms
  def call(conn = %{method: "POST", path_info: ["newRoom"]}, [roomStore]) do
    roomId = Enum.random(0.. 2**20)
    {:ok, roomPid} = GenServer.start(Mweb.RoomManager.Room, [roomId, roomStore])

    GenServer.cast(roomStore, {:addRoom, roomId, roomPid})

    send_whit_cors(conn, 201, Integer.to_string(roomId))
  end

  # Endpoint para obtener todas las rooms actuales
  def call(conn = %{method: "GET", path_info: ["rooms"]}, [roomStore]) do
    roomsMap = GenServer.call(roomStore, {:getRooms})
    rooms = Map.keys(roomsMap)

    {:ok, json} = Jason.encode(rooms)

    send_whit_cors(conn, 200, json)
  end

  def call(conn = %{method: "GET", path_info: [roomId]}, [roomStore]) do
    roomPid = GenServer.call(roomStore, {:getRoom, roomId})

    jugadores = GenServer.call(roomPid, {:getCharacters})
    {:ok, json} = Jason.encode(jugadores)
    send_whit_cors(conn, 200, json)
  end

  def call(conn, _opts) do
    send_whit_cors(conn, 404, "Not found")
  end

  def send_whit_cors(conn, status, body) when is_number(status) do
    # Agrego cabezeras al body para que el navegador no me bloquee las respuestas de este servidor
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type, authorization")
    |> send_resp(status, body)
  end

end
