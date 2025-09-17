function addPlayers(){

    const name = document.getElementById("jugador");

    const options = {
        method: "POST",
      };
    fetch("http://localhost:4000/addPlayer/"+name.value, options)
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
      
    fetch("http://localhost:4000", options)
        .then(response => response.json())
        .then(data => {
            container.innerHTML = "";
            container.innerHTML += "<h1>Aldeanos:</h1>";
            data["aldeanos"].map(a => container.innerHTML += `<p> ${a} </p>`);

            container.innerHTML += "<h1>Mafiosos:</h1>";
            data["mafiosos"].map(a => container.innerHTML += `<p> ${a} </p>`);
        });


}