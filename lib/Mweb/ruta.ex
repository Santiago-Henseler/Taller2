defmodule Mweb.Ruta do
  import Plug.Conn

  def init(roomStore) do
    roomStore
  end

  def call(conn = %{method: "POST", path_info: ["newRoom"]}, [roomStore]) do
    roomId = Enum.random(0.. 2**20)
    {:ok, roomPid} = GenServer.start(Mweb.RoomManager.Room, [roomId, roomStore])

    GenServer.cast(roomStore, {:addRoom, roomId, roomPid})

    send_whit_cors(conn, 201, Integer.to_string(roomId))
  end

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
    # Agrego cabezeras al header para que el navegador no me bloquee las respuestas de este servidor
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type, authorization")
    |> send_resp(status, body)
  end

end
