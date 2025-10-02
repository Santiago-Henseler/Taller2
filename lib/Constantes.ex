defmodule Constantes do 
    @moduledoc false
    @aldeanos 2
    @mafiosos 2
    @policias 0
    @medicos 0

    @tiempo_transicion_estado 1000
    @tiempo_inicio_partida 20000
    @tiempo_debate_grupo 60000      
    @tiempo_debate_final 180000

    defmacro nALDEANOS, do: @aldeanos
    defmacro nMAFIOSOS, do: @mafiosos
    defmacro nPOLICIAS, do: @policias
    defmacro nMEDICOS, do: @medicos
    defmacro nJUGADORES, do: @aldeanos + @mafiosos + @policias + @medicos

    defmacro tINICIO_PARTIDA, do: @tiempo_inicio_partida
    defmacro tTRANSICION, do: @tiempo_transicion_estado
    defmacro tDEBATE_GRUPO, do: @tiempo_debate_grupo
    defmacro tDEBATE_FINAL, do: @tiempo_debate_final
end 