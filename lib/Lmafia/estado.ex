defmodule Lmafia.MaquinaEstados do
  use Machinery,
    states: ["lobby", "mafiosos", "medicos", "policias","debate", "fin"],
    transitions: %{
      "lobby" =>  "mafiosos",
      "mafiosos" => "medicos",
      "medicos" => "policias",
      "policias" => "debate", 
      "debate" => "mafisosos",
      "*" => "fin"
    }
end