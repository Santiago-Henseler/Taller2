defmodule Mweb.RoomManager.Room do
  @moduledoc """
    Modulo encargado de manejar una room
  """
  use GenServer

  alias Mweb.RoomManager.RoomStore
  alias Lmafia.Mafia

  def init(roomId) do
    {:ok, %{roomId: roomId, players: [] }}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_cast({:addPlayer, pid, userId}, state) do
    id = %{userName: userId, pid: pid}
    state = %{state | players: state.players ++ [id]}

    if length(state.players) == 10 do
      {:ok, pid} = GenServer.start_link(Mafia, state.roomId)
      GenServer.cast(pid, {:start, state.players})
    end

    {:noreply, state}
  end

  def handle_cast({:removePlayer, userId},state) do

    new_players = state.players |> Enum.reject(fn player -> player.userName == userId end)

    new_state = %{state | players: new_players}

    case length(new_state.players) do
      0 -> RoomStore.removeRoom(new_state.roomId)
      _ -> :ok
    end

    {:noreply, new_state}

  end

  def handle_call({:getPlayers}, _pid, state) do
    {:reply, state.usuarios, state}
  end

  def handle_call({:canJoin}, _pid, state) do
    case length(state.players) do
      10 ->  {:reply, false, state};
      _  ->  {:reply, true,  state}
    end
  end

  def handle_call(request, _pid, state) do
    {:reply, request, state}
  end

end
