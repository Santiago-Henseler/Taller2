let roomId;
let playerName;

function initSession(){
    const labelName = document.getElementById("jugador");
    playerName = labelName.value;

    document.getElementById("session").style.display = "none";
    getRooms();
}

function getRooms(){

    const roomSelection = document.getElementById("roomSelection")
    roomSelection.style.display = "inline";

    fetch("http://localhost:4000/rooms", {method: "GET"})
    .then(response => response.json())
    .then(data => {
        data.map(id => roomSelection.innerHTML += `<div id="${id}">
                                                        <p>Room: ${id}</p>
                                                        <button style="height: 50px; width: 100px;" onclick="joinRoom(${id})">Unirme</button>
                                                    </div>`)
    });

}

function createRoom(){

    const header = document.getElementById("header");

    fetch("http://localhost:4000/newRoom/"+ playerName, {method: "POST"})
    .then(response => response.text())
    .then(data => {
        roomId = data;
        header.innerHTML += `<center><h1>Room Id: ${roomId}</h1></center>`
    });

}

function joinRoom(id){

    roomId = id

    fetch("http://localhost:4000/"+roomId+"/joinRoom/"+playerName, {method: "POST"})
    .then(response => response.text())
    .then(data => {
        header.innerHTML += `<center><h1>Room Id: ${roomId}</h1></center>`
    });

    header.innerHTML += '<button style="height: 50px; width: 100px;" onclick="getCharacters()">ver jugadores</button>'

    document.getElementById("roomSelection").style.display = "none"
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