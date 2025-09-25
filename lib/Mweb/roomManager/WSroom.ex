defmodule  Mweb.WSroom do
  @behaviour :cowboy_websocket

  def init(req, roomStore) do
    IO.inspect req # req tiene toda la data de la conexion y en roomStore
    {:cowboy_websocket, req, roomStore}
  end

  def websocket_init(roomStore) do
    IO.inspect roomStore
    {:ok, roomStore}
  end

  def websocket_handle({:text, msg}, roomStore) do
    IO.puts("Recibido del cliente: #{msg}")
    {:reply, {:text, "Echo: " <> msg}, roomStore}
  end
  def websocket_handle(_other, roomStore) do
    {:ok, roomStore}
  end

  def websocket_info(info, roomStore) do
    {:reply, {:text, "Server event: #{inspect(info)}"}, roomStore}
  end
end
