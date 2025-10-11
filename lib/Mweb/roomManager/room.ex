defmodule Mweb.RoomManager.Room do
  @moduledoc """
    Modulo encargado de manejar una room
  """
  require Constantes
  use GenServer

  alias Mweb.RoomManager.RoomStore
  alias Lmafia.Mafia

  def init(roomId) do
    {:ok, pid} = GenServer.start_link(Mafia, [])
    {:ok, %{roomId: roomId, players: [], gameController: pid, start: false}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_cast({:addPlayer, pid, userId}, state) do
    id = %{userName: userId, pid: pid, alive: true}
    state = %{state | players: state.players ++ [id]}

    sendPlayers(state)

    state =
      if length(state.players) == Constantes.nJUGADORES and not state.start do
        GenServer.cast(state.gameController, {:start, state.players})
        %{state | start: true}
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:removePlayer, userId},state) do

    new_state = %{state | players: Enum.reject(state.players, fn player -> player.userName == userId end)}

    sendPlayers(new_state)

    case length(new_state.players) do
      0 -> RoomStore.removeRoom(new_state.roomId)
      _ -> :ok
    end

    {:noreply, new_state}

  end

  def handle_cast({:victimSelect, victimId},state) do

    GenServer.cast(state.gameController, {:victimSelect, victimId})

    {:noreply, state}
  end

  def handle_cast({:saveSelect, saveId},state) do

    GenServer.cast(state.gameController, {:saveSelect, saveId})

    {:noreply, state}
  end

  def handle_call({:isMafia, suspectId},_pid,state) when suspectId != nil do
    {:reply, GenServer.call(state.gameController, {:isMafia, suspectId}), state}
  end

  def handle_call({:isMafia, nil},_pid,state) do
    {:reply, "No ingreso sospecha, perdió el turno", state}
  end

  def handle_call({:getPlayers}, _pid, state) do
    {:reply, state.players, state}
  end

  def handle_call({:canJoin}, _pid, state) do
    if state.start do
      {:reply, false, state}
    end

    {:reply, length(state.players) < Constantes.nJUGADORES, state}
  end

  def handle_call(request, _pid, state) do
    {:reply, request, state}
  end

  defp sendPlayers(state) do
    {:ok, json} = Jason.encode(%{type: "users", users: Enum.map(state.players, fn p -> p.userName end)})
    for user <- state.players do
      send(user.pid, {:msg, json})
    end
  end


end
