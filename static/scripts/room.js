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
        document.getElementById("roomSelection").style.display = "none"

        connectWebSocket();
    });
}

function joinRoom(id){

    roomId = id

    fetch("http://localhost:4000/"+roomId+"/joinRoom/", {method: "POST"})
    .then(response => response.text())
    .then(data => {
        header.innerHTML += `<center><h1>Room Id: ${data}</h1></center>`
        document.getElementById("roomSelection").style.display = "none"
        connectWebSocket();
    });
}

function getCharacters(){

    const container = document.getElementById("players");

    const options = {
        method: "GET",
      };
      
    fetch("http://localhost:4000/"+roomId, options)
        .then(response => response.json())
        .then(data => {
            setPlayers(data)
        });
}

function setPlayers(users){

    const container = document.getElementById("players");
    container.innerHTML = `<center>
                                <div>
                                    <h4>Usuarios conectados: ${users}</h4>
                                </div>    
                            </center>`

}
