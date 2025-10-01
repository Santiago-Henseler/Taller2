defmodule Constantes do 
    @moduledoc false
    @aldeanos 2
    @mafiosos 2
    @policias 0
    @medicos 0

    @tiempo_inicio_partida 20000
    @tiempo_debate 50000

    defmacro nALDEANOS, do: @aldeanos
    defmacro nMAFIOSOS, do: @mafiosos
    defmacro nPOLICIAS, do: @policias
    defmacro nMEDICOS, do: @medicos
    defmacro nJUGADORES, do: @aldeanos + @mafiosos + @policias + @medicos

    defmacro tINICIO_PARTIDA, do: @tiempo_inicio_partida
    defmacro tDEBATE, do: @tiempo_debate
end 