defmodule Lmafia.Mafia do
  alias Lmafia.Votacion

  use GenServer

  def init(_param) do

    {:ok, pid} = GenServer.start_link(Votacion, [])

    {:ok,  %{
      aldeanos:  [], # 4 aldeanos
      medicos:   [], # 2 medicos
      mafiosos:  [], # 2 mafiosos
      policias:  [], # 2 policias
      votacion:  pid
    }}
  end

  def handle_cast({:start, players}, gameInfo) do
    gameInfo = gameInfo
      |> setCharacters(players)
      |> sendCharacterToPlayer()

    Process.send_after(self(), :selectVictim, 20000) # A los 20 segundos inicia la partida
    {:noreply, gameInfo}
  end

  def handle_cast({:victimSelect, victimId}, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, victimId})
    {:noreply, gameInfo}
  end

  def handle_cast(:kill, gameInfo) do

    killed = GenServer.call(gameInfo.votacion, :getWin)
    GenServer.cast(gameInfo.votacion, :restart)

    # marcar como muerto al killed
    kill(killed, gameInfo)

    Process.send_after(self(), :medics, 1000) # Al segundo levanto a los medicos

    {:noreply, gameInfo}
  end

  def handle_cast({:revive, userName}, gameInfo) do

    revive(userName, gameInfo)

    {:noreply, gameInfo}
  end

  def handle_call({:isMafia, userName}, _pid, gameInfo) do
    if Map.get(gameInfo.mafiosos, userName) == nil do
      {:reply, false, gameInfo}
    else
      {:reply, true, gameInfo}
    end
  end

  def handle_info(:selectVictim, gameInfo) do
    victims = gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias
    Enum.each(gameInfo.mafiosos, fn x ->
      if x.alive == true do
        {:ok, json} = Jason.encode(%{type: "action", action: "selectVictim", victims: Enum.map(victims, fn p -> p.userName end)})
        send(x.pid, {:msg, json})
      end
    end)
    {:noreply, gameInfo}
  end

  def handle_info(:discussion, gameInfo) do
    users = gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias ++ gameInfo.mafiosos
    Enum.each(users, fn x ->
      if x.alive == true do
        {:ok, json} = Jason.encode(%{type: "action", action: "discussion", victims: Enum.map(users, fn p -> p.userName end)})
        send(x.pid, {:msg, json})
      end
    end)
    {:noreply, gameInfo}
  end

  defp kill(userName, gameInfo) do
    Map.update(gameInfo.mafiosos, userName, nil, fn u -> %{u | alive: false} end)
    Map.update(gameInfo.aldeanos, userName, nil, fn u -> %{u | alive: false} end)
    Map.update(gameInfo.policias, userName, nil, fn u -> %{u | alive: false} end)
    Map.update(gameInfo.medicos,  userName, nil, fn u -> %{u | alive: false} end)
  end

  defp revive(userName, gameInfo) do
    Map.update(gameInfo.mafiosos, userName, nil, fn  u -> if not u.alive do %{u | alive: true} end end)
    Map.update(gameInfo.aldeanos, userName, nil, fn  u -> if not u.alive do %{u | alive: true} end end)
    Map.update(gameInfo.policias, userName, nil, fn  u -> if not u.alive do %{u | alive: true} end end)
    Map.update(gameInfo.medicos,  userName, nil, fn  u -> if not u.alive do %{u | alive: true} end end)
  end

  defp setCharacters(gameInfo, players) do

    players = Enum.shuffle(players)

    {aldeanos, rest}   = Enum.split(players, 2)
    #{medicos, rest}    = Enum.split(rest, 2)
    {mafiosos, rest}   = Enum.split(rest, 8)
    #{policias, _rest}  = Enum.split(rest, 2)

    %{gameInfo | aldeanos: aldeanos, mafiosos: mafiosos}#  ,medicos:  medicos, policias:  policias
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
