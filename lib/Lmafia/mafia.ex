defmodule Lmafia.Mafia do

  defmodule State do
    def init, do: :init
  end

  use GenServer

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

    gameInfo
  end

  defp setCharacters(players, gameInfo) do

    players = Enum.shuffle(players)

    {aldeanos, players}  = Enum.split(players, 4)
    {medicos, players}   = Enum.split(players, 2)
    {mafiosos, players}  = Enum.split(players, 2)
    {policias, _players}  = Enum.split(players, 2)

    %{gameInfo | aldeanos: aldeanos,medicos:  medicos, mafiosos: mafiosos, policias:  policias}
  end

  defp sendCharacterToPlayer(characters) do

    Enum.each(characters.aldeanos, fn x ->
      send(x.pid, "Aldeano")
    end)
    Enum.each(characters.medicos, fn x ->
      send(x.pid, "Medico")
    end)
    Enum.each(characters.mafiosos, fn x ->
      send(x.pid, "Mafioso")
    end)
    Enum.each(characters.policias, fn x ->
      send(x.pid, "Policia")
    end)

    characters
  end



end
