defmodule Room do
  @moduledoc """
  Documentation for `Room`.
  """
  use GenServer

  ### Funciones para implementar GenServer(para correr este modulo como un proceso) ###
  #   Las cast sirven para modificar la variable que persiste
  #   Las call son iguales que las call pero tambien devuelven info en su return

  def init(_params) do
    {:ok, %{usuarios: []}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_cast({:addPlayer, id}, state) do
    state = %{state | usuarios: state.usuarios ++ [id]}
    IO.inspect state
    {:noreply, state}
  end

  def handle_call({:getCharacters}, _pid, state) do
    {:reply, state.usuarios, state}
  end

  def handle_call(request, _pid, state) do
    {:reply, request, state}
  end

end
