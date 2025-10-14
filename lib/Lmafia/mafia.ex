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
      sobredosis: [],
    }}
  end

  def handle_cast({:start, players}, gameInfo) do
    # Seteamos roles e informamos jugadores     
    gameInfo = gameInfo
      |> setCharacters(players)
      |> sendCharacterToPlayer()

    dbg(gameInfo)

    Process.send_after(self(), :selectVictim, Timing.get_time(:start)) # A los 20 segundos inicia la partida
    {:noreply, gameInfo}
  end

  def handle_cast({:victimSelect, victimId}, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, victimId})
#    {:noreply, kill(saveId, gameInfo)}
    {:noreply, gameInfo}
  end

  def handle_cast({:saveSelect, saveId}, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, saveId})
#    {:noreply, revive(saveId, gameInfo)}
    {:noreply, gameInfo}
  end

  def handle_cast({:finalVoteSelect, voted}, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, voted})
    {:noreply, gameInfo}
  end

  def handle_call({:isMafia, userName}, _pid, gameInfo) do
    {:reply, isMafia(gameInfo.mafiosos,userName), gameInfo}
  end

  def handle_info(:selectVictim, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:selectVictim)
    victims = get_jugadores(:vivos,gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "selectVictim", victims: Enum.map(victims, fn p -> p.userName end), timestamp_select_victims: timestamp})
    multicast(gameInfo.mafiosos, json)
    Process.send_after(self(), :kill, Timing.get_time(:selectVictim))
    {:noreply, gameInfo}
  end

  def handle_info(:kill, gameInfo) do
    victimSelect = getWin(gameInfo, :mafiosos)
    gameInfo = %{gameInfo | victimSelect: victimSelect}
#    gameInfo = kill(victimSelect, gameInfo)

    Process.send_after(self(), :medics, Timing.get_time(:transicion)) # Al segundo levanto a los medicos
    {:noreply, gameInfo}
  end

  def handle_info(:medics, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:medics)
    players = get_jugadores(:vivos,gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "savePlayer", players: Enum.map(players, fn p -> p.userName end), timestamp_select_saved: timestamp})
    multicast(gameInfo.medicos, json)

    Process.send_after(self(), :cure, Timing.get_time(:medics))
    {:noreply, gameInfo}
  end

  def handle_info(:cure, gameInfo) do
    {sobredosis, curados} = getWin(gameInfo, :medics)
#    gameInfo = revive(curados, gameInfo)
    gameInfo = %{gameInfo | saveSelect: curados, sobredosis: sobredosis}

    Process.send_after(self(), :policias, Timing.get_time(:transicion)) # Al segundo levanto a los medicos
    {:noreply, gameInfo}
  end


  def handle_info(:policias, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:policias)
    players = get_jugadores(:vivos,gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "selectGuilty", players: Enum.map(players, fn p -> p.userName end), timestamp_select_guilty: timestamp})
    multicast(gameInfo.policias, json)
    
    Process.send_after(self(), :preDiscussion, Timing.get_time(:policias))
    {:noreply, gameInfo}
  end

  def handle_info(:preDiscussion, gameInfo) do
    {result,gameInfo} = night_result(gameInfo)
    timestamp = Timing.get_timestamp_stage(:preDiscussion)
    players = get_jugadores(:all, gameInfo)     
    {:ok, json} = Jason.encode(%{type: "action", action: "nightResult", result: result, timestamp_select_guilty: timestamp})
    multicast(players, json)
    
    Process.send_after(self(), :discussion, Timing.get_time(:preDiscussion))
    {:noreply, gameInfo}
  end

  def handle_info(:discussion, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:discussion)
    users = get_jugadores(:vivos,gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "discusion", players: Enum.map(users, fn p -> p.userName end), timestamp_final_discusion: timestamp})
    multicast(users,json)
    
    Process.send_after(self(), :defineDiscussion, Timing.get_time(:discussion))
    {:noreply, gameInfo}
  end

  def handle_info(:defineDiscussion, gameInfo) do
    # Si hubo quorum para echar a alguien, se lo echa
    echado = getWin(gameInfo, :discussion)
    gameInfo = user_pasa_a_muertos(gameInfo,echado)    
    mensaje = ""
    if echado do 
      mensaje = "Decision final: " + echado + " fue linchado"
    else 
      mensaje = "Nadie fue linchado"
    end 

    timestamp = Timing.get_timestamp_stage(:transicion)
    users = get_jugadores(:all, gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "discusionResult", mensaje: mensaje, timestamp_define_discusion: timestamp})
    multicast(users,json)

    Process.send_after(self(), :endDiscussion, Timing.get_time(:transicion))
    {:noreply, gameInfo}
  end

  def handle_info(:endDiscussion, gameInfo) do
    # Si hubo quorum para echar a alguien, se lo echa
    gameInfo = user_pasa_a_muertos(gameInfo,getWin(gameInfo, :discussion))    
  
    # Definicion final
    # Si cant mafiosos >= cant resto  -> Ganaron los mafiosos
    # Si cant mafiosos = 0            -> Gano el pueblo
    # Sino, sigue el juego   
    cant_mafiosos = get_len_vivos(:mafiosos, gameInfo)
    cant_pueblo = get_len_vivos(:pueblo, gameInfo)

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
    users = get_jugadores(:all, gameInfo)
    mensaje = "Gano el pueblo!!!!"
    {:ok, json} = Jason.encode(%{type: "action", action: "goodEnding", mensaje: mensaje})
    multicast(users,json)

    {:noreply, gameInfo}
  end

  def handle_info(:badEnding, gameInfo) do
    users = get_jugadores(:all, gameInfo)
    mensaje = "Ganaron los mafiosos :( "
    {:ok, json} = Jason.encode(%{type: "action", action: "badEnding", mensaje: mensaje})
    multicast(users,json)

    {:noreply, gameInfo}
  end

  defp get_jugadores(:all,gameInfo) do 
    players = gameInfo.mafiosos ++ gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias ++ gameInfo.muertos
    players = Enum.shuffle(players)
    Enum.map(players, fn x -> if x.alive do x end end)      
  end 

  defp get_jugadores(:vivos,gameInfo) do 
    players = gameInfo.mafiosos ++ gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias
    players = Enum.shuffle(players)
    Enum.map(players, fn x -> if x.alive do x end end)      
  end

  defp get_len_vivos(:mafiosos, gameInfo), do: Enum.count(gameInfo.mafiosos, fn x -> x.alive end)
  defp get_len_vivos(:policias, gameInfo), do: Enum.count(gameInfo.policias, fn x -> x.alive end)
  defp get_len_vivos(:aldeanos, gameInfo), do: Enum.count(gameInfo.aldeanos, fn x -> x.alive end)
  defp get_len_vivos(:medicos, gameInfo), do: Enum.count(gameInfo.medicos, fn x -> x.alive end)
  defp get_len_vivos(:pueblo, gameInfo) do
    get_len_vivos(:aldeanos, gameInfo) + get_len_vivos(:policias, gameInfo) + get_len_vivos(:medicos, gameInfo) 
  end 

  defp kill(nil, gameInfo), do: gameInfo 
  defp kill(userName, gameInfo), do: changeAliveState(userName, false, gameInfo)

  defp revive(userName, gameInfo), do: changeAliveState(userName, true, gameInfo)

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

  defp user_pasa_a_muertos(gameInfo, nil), do: gameInfo

  defp user_pasa_a_muertos(gameInfo, userName) do
    {mafiosos_muertos,mafiosos} = user_en_grupo_pasa_a_muertos(gameInfo.mafiosos, userName)
    {aldeanos_muertos,aldeanos} = user_en_grupo_pasa_a_muertos(gameInfo.aldeanos, userName)
    {policias_muertos,policias} = user_en_grupo_pasa_a_muertos(gameInfo.policias, userName)
    {medicos_muertos,medicos}   = user_en_grupo_pasa_a_muertos(gameInfo.medicos , userName)

    muertos = gameInfo.muertos ++ medicos_muertos ++ mafiosos_muertos ++ aldeanos_muertos ++ policias_muertos   
    %{gameInfo | aldeanos: aldeanos, mafiosos: mafiosos ,medicos:  medicos, policias:  policias, muertos: muertos}
  end

  defp user_en_grupo_pasa_a_muertos(lista_grupo, userName) do
    Enum.split_with(lista_grupo, fn player -> player.userName == userName end)
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

  defp getWin(gameInfo, stage) do
    winner = GenServer.call(gameInfo.votacion, :getWin, stage)
    GenServer.cast(gameInfo.votacion, :restart)

    winner
  end

  defp night_result(gameInfo) do 
    # TODO: Programar casos
    result = ""
    if gameInfo.victimSelect do 
      if gameInfo.victimSelect in gameInfo.saveSelect do 
        result = "La mafia quizo asesinar a " <> gameInfo.victimSelect <> " pero fue salvado por los medicos"
      else
        gameInfo = user_pasa_a_muertos(gameInfo,gameInfo.victimSelect)
        result = "La mafia asesino a " <> gameInfo.victimSelect 
        if gameInfo.victimSelect in gameInfo.sobredosis do 
          result = result <> " y mientras agonizaba recibio una sobredosis de cura"
        end
      end 
    else 
      result = "La mafia no asesino a nadie"
    end 

    result = result <> "\nMuertos por sobredosis:\n"
    Enum.each(gameInfo.sobredosis, fn name -> 
      if name != gameInfo.victimSelect do 
        gameInfo = user_pasa_a_muertos(gameInfo,name)
        result = result <> name       
      end  
    end)

    {result,reset_selectors(gameInfo)}
  end 

  defp reset_selectors(gameInfo) do 
    %{gameInfo | victimSelect: nil, saveSelect: [], sobredosis: []}
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
