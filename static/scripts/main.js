let roomId;

window.onload = () =>{
    const options = {
        method: "POST",
      };
    fetch("http://localhost:4000/newRoom/Juan", options)
    .then(response => response.text())
    .then(data => {
        roomId = data;
        alert(roomId)
    });

}

function addPlayers(){

    const name = document.getElementById("jugador");

    const options = {
        method: "POST",
      };
    fetch("http://localhost:4000/"+roomId+"/addPlayer/"+name.value, options)
    .then(response => response.text())
    .then(data => {
        alert("el jugador " + data + " fue agregado con exito")
    });

    name.value = "";
}

function getCharacters(){

    const container = document.getElementById("players");

    const options = {
        method: "GET",
      };
      
    fetch("http://localhost:4000/"+roomId, options)
        .then(response => response.json())
        .then(data => {
           alert(data)
        });


}