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

    fetch("http://localhost:4000/newRoom/", {method: "POST"})
    .then(response => response.text())
    .then(data => {
        roomId = data;
        header.innerHTML += `<center><h1>Room Id: ${roomId}</h1></center>`
        connectWebSocket();
    });

}

function joinRoom(id){

    roomId = id

    fetch("http://localhost:4000/"+roomId+"/joinRoom/", {method: "POST"})
    .then(response => response.text())
    .then(data => {
        header.innerHTML += `<center><h1>Room Id: ${data}</h1></center>`
    });

    header.innerHTML += '<button style="height: 50px; width: 100px;" onclick="getCharacters()">ver jugadores</button>'

    document.getElementById("roomSelection").style.display = "none"

    connectWebSocket();
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

function connectWebSocket(){
    let socket = new WebSocket("ws://localhost:4000/ws/"+roomId+"/"+playerName)

    socket.onopen = () => {
        socket.send("hola servidor")
        setInterval(() => {
            if (socket.readyState === WebSocket.OPEN) {
                socket.send(JSON.stringify({type: "ping"}));
            }
        }, 25000);
    }

    socket.onmessage = (event) => {
        console.log("Mensaje del server:", event.data)
    }

}