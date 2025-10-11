defmodule Lmafia.Mafia do
  require Constantes
  require Timing
  alias Lmafia.Votacion

  use GenServer

  def init(_param) do

    {:ok, pid} = GenServer.start_link(Votacion, [])

    {:ok,  %{
      aldeanos:  [], # 4 aldeanos
      medicos:   [], # 2 medicos
      mafiosos:  [], # 2 mafiosos
      policias:  [], # 2 policias
      
      votacion:  pid,
      victimSelect: nil,
      saveSelect: [],
    }}
  end

  def handle_cast({:start, players}, gameInfo) do
    # Seteamos roles e informamos jugadores     
    gameInfo = gameInfo
      |> setCharacters(players)
      |> sendCharacterToPlayer()

    Process.send_after(self(), :selectVictim, Timing.get_time(:start)) # A los 20 segundos inicia la partida
    {:noreply, gameInfo}
  end

  def handle_cast({:victimSelect, victimId}, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, victimId})
    {:noreply, gameInfo}
  end

  def handle_cast({:saveSelect, saveId}, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, saveId})
#    {:noreply, revive(saveId, gameInfo)}
    {:noreply, gameInfo}
  end

  def handle_cast({:finalVoteSelect, voted}, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, voted})
#    {:noreply, revive(saveId, gameInfo)}
    {:noreply, gameInfo}
  end

  def handle_call({:isMafia, userName}, _pid, gameInfo) do
    {:reply, isMafia(gameInfo.mafiosos,userName), gameInfo}
  end

  def handle_info(:selectVictim, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:selectVictim)
    victims = get_jugadores_vivos(gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "selectVictim", victims: Enum.map(victims, fn p -> p.userName end), timestamp_select_victims: timestamp})
    multicast(gameInfo.mafiosos, json)
    Process.send_after(self(), :kill, Timing.get_time(:selectVictim))
    {:noreply, gameInfo}
  end

  def handle_info(:kill, gameInfo) do
    killed = getWin(gameInfo)
    gameInfo = kill(killed, gameInfo)

    Process.send_after(self(), :medics, Timing.get_time(:transicion)) # Al segundo levanto a los medicos
    {:noreply, %{gameInfo | victimSelect: killed}}
  end

  def handle_info(:medics, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:medics)
    players = get_jugadores_vivos(gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "savePlayer", players: Enum.map(players, fn p -> p.userName end), timestamp_select_saved: timestamp})
    multicast(gameInfo.medicos, json)

    Process.send_after(self(), :cure, Timing.get_time(:medics))
    {:noreply, gameInfo}
  end

  def handle_info(:cure, gameInfo) do
    cured = getWin(gameInfo)
    gameInfo = revive(cured, gameInfo)

    Process.send_after(self(), :policias, Timing.get_time(:transicion)) # Al segundo levanto a los medicos
    {:noreply, %{gameInfo | saveSelect: cured}}
  end


  def handle_info(:policias, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:policias)
    players = get_jugadores_vivos(gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "selectGuilty", players: Enum.map(players, fn p -> p.userName end), timestamp_select_guilty: timestamp})
    multicast(gameInfo.policias, json)
    
    Process.send_after(self(), :discussion, Timing.get_time(:policias))
    {:noreply, gameInfo}
  end

  def handle_info(:discussion, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:discussion)
    users = get_jugadores_vivos(gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "discusion", players: Enum.map(users, fn p -> p.userName end), timestamp_final_discusion: timestamp})
    multicast(users,json)
    
    Process.send_after(self(), :endDiscussion, Timing.get_time(:discussion))
    {:noreply, gameInfo}
  end

  def handle_info(:endDiscussion, gameInfo) do
    IO.puts "DEBUG End Discussion"
    # Si hubo quorum para echar a alguien, se lo echa
    gameInfo = kill(getWin(gameInfo), gameInfo)
  
    # Definicion final
    # Si cant mafiosos >= cant resto  -> Ganaron los mafiosos
    # Si cant mafiosos = 0            -> Gano el pueblo
    # Sino, sigue el juego   
    cant_mafiosos = get_len_vivos_grupo(gameInfo.mafiosos)
    cant_pueblo = get_len_vivos_grupo(gameInfo.aldeanos ++ gameInfo.medicos ++ gameInfo.policias)

    timestamp = Timing.get_time(:transicion)
    cond do
      cant_mafiosos == 0 -> 
        Process.send_after(self(), :goodEnding, timestamp)
      cant_mafiosos >= cant_pueblo ->
        Process.send_after(self(), :badEnding, timestamp)
      true ->
        Process.send_after(self(), :selectVictim, timestamp)
      end
    
    {:noreply, gameInfo}
  end  

  def handle_info(:goodEnding, gameInfo) do
    # TODO: Good ending (GANO EL PUEBLO)    
    {:noreply, gameInfo}
  end

  def handle_info(:badEnding, gameInfo) do
    # TODO: Bad ending  (GANO LA MAFIA)
    {:noreply, gameInfo}
  end

  defp get_jugadores_vivos(gameInfo) do 
    players = gameInfo.mafiosos ++ gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias
    players = Enum.shuffle(players)
    Enum.map(players, fn x -> if x.alive do x end end)      
  end

  defp get_len_vivos_grupo(grupo) do
    Enum.count(grupo, fn x -> x.alive end)
  end

  defp kill(nil, gameInfo), do: gameInfo 
  
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
#    players = Enum.shuffle(players)

    {aldeanos, rest}  = Enum.split(players, Constantes.nALDEANOS)
    {medicos,  rest}  = Enum.split(rest, Constantes.nMEDICOS)
    {mafiosos, rest}  = Enum.split(rest, Constantes.nMAFIOSOS)
    {policias, _rest} = Enum.split(rest, Constantes.nPOLICIAS)

    %{gameInfo | aldeanos: aldeanos, mafiosos: mafiosos ,medicos:  medicos, policias:  policias}
  end

  defp sendCharacterToPlayer(characters) do
    timestamp = Timing.get_timestamp_stage(:start)

    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Aldeano", timestamp_game_starts: timestamp})
    multicast(characters.aldeanos, json)
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Medico", timestamp_game_starts: timestamp})
    multicast(characters.medicos, json)
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Mafioso", timestamp_game_starts: timestamp})
    multicast(characters.mafiosos, json)
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Policia", timestamp_game_starts: timestamp})
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

  defp getWin(gameInfo) do
    winner = GenServer.call(gameInfo.votacion, :getWin)
    GenServer.cast(gameInfo.votacion, :restart)

    winner
  end

  defp isMafia(mafiosos, username ) do
    isMafia = Enum.any?(mafiosos, fn m -> m.userName == username end) 
    format_isMafia_answer(isMafia,username)
  end

  defp format_isMafia_answer(isMafia,username) when is_integer(username) do
    format_isMafia_answer(isMafia,to_string(username))
  end

  defp format_isMafia_answer(isMafia,player) do
    "#{player}#{if isMafia, do: "", else: " no"} es un mafioso"  
  end

end
