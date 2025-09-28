defmodule Lmafia.Mafia do

  use GenServer

  defmodule State do
    def init, do: :init
    def charSet, do: :charSet
    def mafiaKill, do: :mafiaKill
    def med1, do: :med1
    def med2, do: :med2
    def debate, do: :debate
  end

  def init(roomId) do
    {:ok,  %{
      roomId: roomId,
      aldeanos:  [], # 4 aldeanos
      medicos:   [], # 2 medicos
      mafiosos:  [], # 2 mafiosos
      policias:  [],  # 2 policias
      state: State.init()
    }}
  end

  def handle_cast({:start, players}, gameInfo) do
    gameInfo =
      if gameInfo.state == :init do
        gameInfo
        |> setCharacters(players)
        |> sendCharacterToPlayer()
      else
        gameInfo
      end
    {:noreply, %{gameInfo | state: State.charSet()}}
  end

  def handle_call({:move, move},_pid, gameInfo) do

    {:noreply, %{gameInfo | state: State.charSet()}}
  end

  def handle_info(:send, gameInfo) do

    gameInfo = if gameInfo.state in [:charSet, :debate] do
      Enum.each(gameInfo.mafiosos, fn x ->
        if x.alive == true do
          {:ok, json} = Jason.encode(%{type: "action", action: "selectVictim"})
          send(x.pid, {:msg, json})
        end
      end)
      %{gameInfo | state: State.mafiaKill()}
    end

    {:noreply, gameInfo}
  end

  defp setCharacters(gameInfo, players) do

    players = Enum.shuffle(players)

    {aldeanos, players}  = Enum.split(players, 4)
    {medicos, players}   = Enum.split(players, 2)
    {mafiosos, players}  = Enum.split(players, 2)
    {policias, _players}  = Enum.split(players, 2)

    %{gameInfo | aldeanos: aldeanos,medicos:  medicos, mafiosos: mafiosos, policias:  policias}
  end

  defp sendCharacterToPlayer(characters) do

    Enum.each(characters.aldeanos, fn x ->
      {:ok, json} = Jason.encode(%{type: "characterSet", character: "Aldeano"})
      send(x.pid, {:msg, json})
    end)
    Enum.each(characters.medicos, fn x ->
      {:ok, json} = Jason.encode(%{type: "characterSet", character: "Medico"})
      send(x.pid, {:msg, json})
    end)
    Enum.each(characters.mafiosos, fn x ->
      {:ok, json} = Jason.encode(%{type: "characterSet", character: "Mafioso"})
      send(x.pid, {:msg, json})
    end)
    Enum.each(characters.policias, fn x ->
      {:ok, json} = Jason.encode(%{type: "characterSet", character: "Policia"})
      send(x.pid, {:msg, json})
    end)

    characters
  end



end
