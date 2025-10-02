defmodule Lmafia.Mafia do
  require Constantes
  alias Lmafia.Votacion

  use GenServer

  def init(_param) do

    {:ok, pid} = GenServer.start_link(Votacion, [])

    {:ok,  %{
      aldeanos:  [], # 4 aldeanos
      medicos:   [], # 2 medicos
      mafiosos:  [], # 2 mafiosos
      policias:  [], # 2 policias
      muertos:   [], 
      votacion:  pid,
      victimSelect: nil,
      saveSelect: nil,
    }}
  end

  def handle_cast({:start, players}, gameInfo) do
    gameInfo = gameInfo
      |> setCharacters(players)
      |> sendCharacterToPlayer()
          
    Process.send_after(self(), :selectVictim, Constantes.tINICIO_PARTIDA) # A los 20 segundos inicia la partida
    {:noreply, gameInfo}
  end

  def handle_cast({:victimSelect, victimId}, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, victimId})
    {:noreply, gameInfo}
  end

  def handle_cast({:saveSelect, saveId}, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, saveId})
    {:noreply, revive(saveId, gameInfo)}
  end

  def handle_call({:isMafia, userName}, _pid, gameInfo) do
    {:reply, Map.get(gameInfo.mafiosos, userName) != nil, gameInfo}
  end

  def handle_info(:selectVictim, gameInfo) do
    # selecionar victimas vivas
    victims = gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias 
    {:ok, json} = Jason.encode(%{type: "action", action: "selectVictim", victims: Enum.map(victims, fn p -> p.userName end)})
    multicast(gameInfo.mafiosos, json)
    Process.send_after(self(), :kill, 13000)
    {:noreply, gameInfo}
  end

  def handle_info(:kill, gameInfo) do

    killed = GenServer.call(gameInfo.votacion, :getWin)
    GenServer.cast(gameInfo.votacion, :restart)

    gameInfo = kill(killed, gameInfo)

    Process.send_after(self(), :medics, Constantes.tTRANSICION) # Al segundo levanto a los medicos

    {:noreply, %{gameInfo | victimSelect: killed}}
  end

  def handle_info(:medics, gameInfo) do
    players = gameInfo.mafiosos ++ gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias
    {:ok, json} = Jason.encode(%{type: "action", action: "savePlayer", players: Enum.map(players, fn p -> p.userName end)})
    multicast(gameInfo.medicos, json)
    Process.send_after(self(), :cops, 13000)

    {:noreply, gameInfo}
  end

  def handle_info(:cops, gameInfo) do
    players = gameInfo.mafiosos ++ gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias
    {:ok, json} = Jason.encode(%{type: "action", action: "selectGuilty", players: Enum.map(players, fn p -> p.userName end)})
    multicast(gameInfo.medicos, json)
    
    Process.send_after(self(), :discussion, 13000)
    {:noreply, gameInfo}
  end

  def handle_info(:discussion, gameInfo) do
    users = gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias ++ gameInfo.mafiosos
    {:ok, json} = Jason.encode(%{type: "action", action: "discussion", victims: Enum.map(users, fn p -> p.userName end)})
    multicast(users,json)
    
    Process.send_after(self(), :endDiscussion, Constantes.tDEBATE_FINAL)
    {:noreply, gameInfo}
  end

  def handle_info(:endDiscussion, gameInfo) do
    # TODO: Implementar decision final del juego
    # Si hubo quorum para echar a alguien, se lo echa
    # Si cant mafiosos >= cant resto  -> Ganaron los mafiosos
    # Si cant mafiosos = 0            -> Gano el pueblo
    # Sino, sigue el juego   

    Process.send_after(self(), :selectVictim, Constantes.tTRANSICION)
    {:noreply, gameInfo}
  end

  defp kill(userName, gameInfo) do
    changeAliveState(userName, false, gameInfo)
  end

  defp revive(userName, gameInfo) do
    changeAliveState(userName, true, gameInfo)
  end

  defp changeAliveState(userName, alive, gameInfo) do
    mafiosos = changeAlive(gameInfo.mafiosos, userName, alive)
    aldeanos = changeAlive(gameInfo.aldeanos, userName, alive)
    policias = changeAlive(gameInfo.policias, userName, alive)
    medicos =  changeAlive(gameInfo.medicos, userName, alive)

    %{gameInfo | aldeanos: aldeanos, mafiosos: mafiosos, policias: policias, medicos: medicos}
  end

  defp changeAlive(players, userName, alive) do
    Enum.map(players, fn x ->
      if x == userName do
        %{x | alive: alive}
      else
        x
      end end)
  end

  defp setCharacters(gameInfo, players) do

    players = Enum.shuffle(players)

    {aldeanos, rest}    = Enum.split(players, Constantes.nALDEANOS)
    #{medicos, rest}    = Enum.split(rest, Constantes.nMEDICOS)
    {mafiosos, _rest}   = Enum.split(rest, Constantes.nMAFIOSOS)
    #{policias, _rest}   = Enum.split(rest, Constantes.nPOLICIAS)

    %{gameInfo | aldeanos: aldeanos, mafiosos: mafiosos} #,medicos:  medicos, policias:  policias}
  end

  defp sendCharacterToPlayer(characters) do
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Aldeano"})
    multicast(characters.aldeanos, json)
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Medico"})
    multicast(characters.medicos, json)
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Mafioso"})
    multicast(characters.mafiosos, json)
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Policia"})
    multicast(characters.policias, json)

    characters
  end

  defp multicast(clientes, mensaje_json) do
    Enum.each(clientes, fn x ->
      if x.alive == true do
        send(x.pid, {:msg, mensaje_json})
      end
    end)
  end 

end
