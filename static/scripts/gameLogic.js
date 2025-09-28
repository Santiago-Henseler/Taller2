let character = null;

function setCharacter(characterType){
    character = characterType

    document.body.innerHTML += `<center><h3>Sos un ${character}</h3></center>`;
}

function startGame(){
    document.body.innerHTML += '<h3 id="startTimer"></h3>'

    timer(20, (time)=>{
        let timer = document.getElementById("startTimer")
        timer.innerText = "La partida inica en " +time;

        if(time == 1){
            timer.style.display = "none"
        }
    })
}

function doAction(action){

    switch(action.action){
        case "selectVictim":
            selectVictim(action.victims)
            break;
    }

}

function selectVictim(victims){
    alert(victims)
}

function timer(time, fn){

    let cuentaRegresiva = setInterval(() => {
        fn(time)
        time--;
        if(time == 0){
            clearInterval(cuentaRegresiva);
        }
    }, 1000);

}
