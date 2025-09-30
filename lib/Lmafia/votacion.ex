defmodule Lmafia.Votacion do

  use GenServer

  def init(_param) do
    {:ok,  %{}}
  end

  def handle_cast(:restart, _voteInfo) do
    IO.puts "Handle cast :restart"
    {:noreply, %{}}
  end

  def handle_cast({:addVote, vote}, voteInfo) do
    voteInfo |> dbg
    
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
    voteInfo |> IO.inspect 

    {:reply,  getMax(voteInfo), %{}}
  end

  defp getMax(voteInfo) do
    top2 =
      voteInfo |> Enum.sort_by(fn {_k, v} -> v end, :desc) |> Enum.take(2)

    {firstK, firstV} = Enum.at(top2, 0)
    {secondK, secondV} = Enum.at(top2, 1)

    if firstV == secondV do
      elements = [firstK, secondK]
      pos = Enum.random(0..1)
      Enum.at(elements, pos)
    else
      firstK
    end

  end

end
