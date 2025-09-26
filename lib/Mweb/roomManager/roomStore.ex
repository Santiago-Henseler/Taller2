defmodule Mweb.RoomManager.RoomStore do
  @moduledoc """
    Modulo encargado de manterne las distintas rooms almacendas por {roomId: roomPid}
  """
  use GenServer

  def init(_params) do
    rooms = %{}
    {:ok, rooms}
  end

  def handle_info(_msg, rooms) do
    {:noreply, rooms}
  end

  def handle_cast({:addRoom, roomId, roomPid}, rooms) when is_integer(roomId) do
    rooms = Map.put(rooms, roomId, roomPid)
    {:noreply, rooms}
  end

  def handle_cast({:addRoom, roomId, roomPid}, rooms) do
    rooms = Map.put(rooms, String.to_integer(roomId), roomPid)
    {:noreply, rooms}
  end

  def handle_cast({:removeRoom, roomId}, rooms) do
    rooms = Map.delete(rooms, roomId)
    {:noreply, rooms}
  end

  def handle_call({:getRooms}, _pid, rooms) do
    {:reply, rooms, rooms}
  end

  def handle_call({:getRoom, roomId}, _pid, rooms) when is_integer(roomId) do
    {:reply, Map.get(rooms, roomId), rooms}
  end

  def handle_call({:getRoom, roomId}, _pid, rooms)   do
    {:reply, Map.get(rooms, String.to_integer(roomId)), rooms}
  end

  def handle_call(request, _pid, rooms) do
    {:reply, request, rooms}
  end


end
