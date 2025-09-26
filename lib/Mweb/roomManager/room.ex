defmodule Mweb.RoomManager.Room do
  @moduledoc """
    Modulo encargado en manejar las rooms
  """
  use GenServer

  def init([roomId, roomStore]) do
    {:ok, %{
            roomId: roomId,
            usuarios: [], # Guardo todas las conexiones para un broadcast (si es necesario)
            aldeanos: [],
            medicos:  [],
            mafiosos: [],
            roomStorePid: roomStore
            }}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_cast({:addPlayer, ip, userId}, state) do
    id = %{userName: userId, ip: ip}
    state = %{state | usuarios: state.usuarios ++ [id]}
    {:noreply, state}
  end

  def handle_cast({:removePlayer, ip, userId}, state) do
    id = %{userName: userId, ip: ip}
    state = %{state | usuarios: state.usuarios -- [id]}

    case length(state.usuarios) do
      0 ->  GenServer.cast(state.roomStorePid, {:removeRoom, state.roomId})
      _ -> :ok
    end

    {:noreply, state}
  end

  def handle_call({:getCharacters}, _pid, state) do
    {:reply, state.usuarios, state}
  end

  def handle_call(request, _pid, state) do
    {:reply, request, state}
  end

end
