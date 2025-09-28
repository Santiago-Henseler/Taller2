defmodule Mweb.RoomManager.Room do
  @moduledoc """
    Modulo encargado de manejar una room
  """
  use GenServer

  alias Mweb.RoomManager.RoomStore

  def init(roomId) do
    {:ok, %{roomId: roomId, players: [] }}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_cast({:addPlayer, pid, userId}, state) do

    for user <- state.players do
      send(user.pid, state.players)
    end

    id = %{userName: userId, pid: pid}
    state = %{state | players: state.players ++ [id]}
    {:noreply, state}
  end

  def handle_cast({:removePlayer, pid, userId},state) do
    id = %{userName: userId, pid: pid}
    state = %{state | players: state.players -- [id]}

    case length(state.players) do
      0 ->  RoomStore.removeRoom(state.roomId)
      _ -> :ok
    end
    {:noreply, state}
  end

  def handle_call({:getPlayers}, _pid, state) do
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
