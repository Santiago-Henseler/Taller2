defmodule Mafia do
  @moduledoc """
  Documentation for `Mafia`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Mafia.hello()
      :world

  """
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


  def main do
    {players, killers} = 10 |> get_players |> get_characters([],2)   
    IO.puts "List of players: #{inspect(players)}"
    IO.puts "List of killers: #{inspect(killers)}"
  end
end
