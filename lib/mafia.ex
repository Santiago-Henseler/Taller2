defmodule Mafia do
  @moduledoc """
  Documentation for `Mafia`.
  """
  use GenServer

  defp get_players(pending_players) when pending_players >= 1 do
    get_players([],pending_players)
  end

  defp get_players(players,pending_players) when pending_players >= 1 and is_list(players) do
    get_players(players ++ [IO.gets("Input new player name: ")],pending_players-1)
  end

  defp get_players(players,0) when is_list(players) do  # Cuando no matchee la funcion anterior, devolve vacio
    players
  end

  defp get_characters(players, killers, 0) when is_list(players) and is_list(killers) do
    {players, killers}
  end

  defp get_characters(players, killers, pending_killers) when is_list(players) and is_list(killers) and is_number(pending_killers) do
    killer_index = Enum.random(0.. length(players)-1)
    killers = killers ++ [Enum.at(players,killer_index)]
    players = List.delete_at(players, killer_index)

    get_characters(players, killers, pending_killers - 1)
  end


  ### Funciones para implementar GenServer(para correr este modulo como un proceso) ###
  #   Las cast sirven para modificar la variable que persiste
  #   Las call son iguales que las call pero tambien devuelven info en su return

  def init(_params) do
    {:ok, %{usuarios: []}} # Variable que va a persistir con cada llamada
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_cast({:addPlayer, id}, state) do
    state = %{state | usuarios: state.usuarios ++ [id]}
    IO.inspect state
    {:noreply, state}
  end

  def handle_call({:getCharacters}, pid, state) do
    {:reply, get_characters(state.usuarios, [],2), state}
  end

  def handle_call(request, _pid, state) do
    {:reply, request, state}
  end

end
