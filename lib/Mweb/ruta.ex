defmodule Mweb.Ruta do
  import Plug.Conn

  def init(options) do
    IO.inspect(options, label: "init server")
    {:ok, pid} = GenServer.start(Mafia, "")
    pid
  end

  # Recibo un nuevo jugador
  def call(conn = %{method: "POST", path_info: ["addPlayer", id]}, options) do
    GenServer.cast(options, {:addPlayer, id})
    send_whit_cors(conn, 201, id)
  end

  def call(conn = %{method: "GET"}, options) do
    IO.puts "conexion : #{inspect(conn)}"
    {players, killers} = GenServer.call(options, {:getCharacters})
    jugadores = %{
      aldeanos: players,
      mafiosos: killers
    }
    {:ok, json} = Jason.encode(jugadores)
    send_whit_cors(conn, 200, json)
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
