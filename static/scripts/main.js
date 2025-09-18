let roomId;
let playerName;

function initSession(){
    const labelName = document.getElementById("jugador");
    playerName = labelName.value;

    document.getElementById("session").style.display = "none";
    document.getElementById("roomSelection").style.display = "inline";
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

function joinRoom(){

    roomId = document.getElementById("roomId").value;

    fetch("http://localhost:4000/"+roomId+"/joinRoom/"+playerName, {method: "POST"})
    .then(response => response.text())
    .then(data => {
        header.innerHTML += `<center><h1>Room Id: ${roomId}</h1></center>`
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
           alert(data)
        });


}