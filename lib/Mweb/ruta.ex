defmodule Mweb.Ruta do
  import Plug.Conn

  def init(options) do
    IO.inspect(options, label: "init: ")
    options
  end

  def call(conn = %{method: "GET"}, _options) do
    {players, killers} = Mafia.main()
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
