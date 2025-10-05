let character = null;

function setCharacter(characterType){
    character = characterType

    document.body.innerHTML += `<center><h3>Sos un ${character}</h3></center>`;
}

function startGame(timestampGameStarts){
    document.body.innerHTML += '<center><h3 id="startTimer"></h3></center>'
    
    timer( getTimeForNextStage(timestampGameStarts), (time)=>{
        let timer = document.getElementById("startTimer")
        timer.innerText = "La partida inicia en " +time;

        if(time == 1){
            timer.style.display = "none"
        }
    })
}

function doAction(action){

    switch(action.action){
        case "selectVictim":
            selectVictim(action.victims, action.timestamp_select_victims)
            break;
        case "savePlayer":
            savePlayer(action.players)
            break;
        case "selectGuilty":
            selectGuilty(action.players)
            break;
        default: break;
    }
}

function selectGuilty(players){
    
}

function savePlayer(players){

}

function selectVictim(victims, timestampSelectVictim){

    let victim = null;

    document.body.innerHTML += '<div id="victimSeccion"><center><h2>Selecciona tu victima</h2><h3 id="victimTimer"></h3></center></div>'
    let victimSeccion = document.getElementById("victimSeccion")
    
    timer(getTimeForNextStage(timestampSelectVictim), (time)=>{
        let timer = document.getElementById("victimTimer")
        timer.innerText = "La seleccion de victima termina en " +time;

        if(time == 1){
            timer.style.display = "none"
            socket.send(JSON.stringify({roomId: roomId, type: "victimSelect", victim: victim}));
        }
    })

    for(let victim of victims){
        victimSeccion.insertAdjacentHTML("beforeend", `
        <label>
            <input type="radio" name="victim" value="${victim}"> ${victim}
        </label>
        <label id="${victim}Count"></label>
        <br>
    `);
    }

    const radios = document.querySelectorAll('input[name="victim"]');
    const resultado = document.getElementById("resultado");

    radios.forEach(radio => {
      radio.addEventListener("change", () => {
        victim = radio.value
      });
    })
}

function timer(time, fn){
    console.log("Time = " + time)
    let cuentaRegresiva = setInterval(() => {
        fn(time)
        time--;
        if(time == 0){
            clearInterval(cuentaRegresiva);
        }
    }, 1000);

}

function getTimeForNextStage(timestampNextStage) {
    let CurrentDate = new Date()
    let NextStageDate = new Date(timestampNextStage)
    let result = Math.floor( ( NextStageDate.getTime() - CurrentDate.getTime() ) / 1000  )

    console.debug("Current date " + CurrentDate )
    console.debug("Next Stage " + NextStageDate )
    console.debug("Seconds result " + result )

    if (result > 0) 
        return result
    else {
        console.warn("Este cliente se quedo detras por " + result + " segundos")
        return 1 
    }
}
