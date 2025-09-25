defmodule Mweb.RoomManager.Room do
  @moduledoc """
    Modulo encargado en manejar las rooms
  """
  use GenServer

  def init(_params) do
    {:ok, %{
            usuarios: [], # Guardo todas las conexiones para un broadcast (si es necesario)
            aldeanos: [],
            medicos:  [],
            mafiosos: [],
            }}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_cast({:addPlayer, id, conn}, state) do
    IO.inspect conn
    state = %{state | usuarios: state.usuarios ++ [id]}
    {:noreply, state}
  end

  def handle_call({:getCharacters}, _pid, state) do
    {:reply, state.usuarios, state}
  end

  def handle_call(request, _pid, state) do
    {:reply, request, state}
  end

end
