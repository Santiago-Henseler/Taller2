defmodule Lmafia.Votacion do

  use GenServer

  def init(_param) do
    {:ok,  %{}}
  end

  def handle_cast(:restart, _voteInfo) do
    {:noreply, %{}}
  end

  def handle_cast({:addVote, vote}, voteInfo) do
    len = Map.get(voteInfo, vote)

    voteInfo =
      if len == nil do
        Map.put(voteInfo, vote, 1)
      else
        Map.put(voteInfo, vote, len+1)
      end

    {:noreply, voteInfo}
  end

  def handle_cast({:removeVote, vote}, voteInfo) do
    voteInfo |> dbg
    vote |> dbg
    
    len = Map.get(voteInfo, vote)

    voteInfo =
      if len != nil do
        %{voteInfo | vote: len-1}
      end

    {:noreply, voteInfo}
  end

  def handle_call(:getWin, _pid, voteInfo) do
    {:reply,  getMax(voteInfo), voteInfo}
  end

  defp getMax(voteInfo) when map_size(voteInfo) >= 2 do
    top2 =
      voteInfo |> Enum.sort_by(fn {_k, v} -> v end, :desc) |> Enum.take(2)

    {firstK, firstV} = Enum.at(top2, 0)
    {_secondK, secondV} = Enum.at(top2, 1)

    if firstV == secondV do
      # Si hay empate no devuelvo nada (no hubo quorum, se joden por nabos) 
      nil
    else
      firstK
    end
  end

  defp getMax(voteInfo) when map_size(voteInfo) > 0 do
    {firstK, _firstV} = Enum.at(voteInfo, 0)
    firstK
  end

  defp getMax(_voteInfo), do: nil

end
