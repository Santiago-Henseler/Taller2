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

  def handle_cast({:addPlayer, pid, userId}, state) do

    for user <- state.usuarios do
      send(user.pid, state.usuarios)
    end
    id = %{userName: userId, pid: pid}
    state = %{state | usuarios: state.usuarios ++ [id]}
    {:noreply, state}
  end

  def handle_cast({:removePlayer, pid, userId}, state) do
    id = %{userName: userId, pid: pid}
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

  def handle_call({:canJoin}, _pid, state) do
    case length(state.usuarios) do
      10 ->  {:reply, false, state};
      _  ->  {:reply, true,  state}
    end
  end

  def handle_call(request, _pid, state) do
    {:reply, request, state}
  end

end
