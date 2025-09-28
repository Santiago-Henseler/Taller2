let character = null;

function setCharacter(characterType){
    character = characterType

    document.body.innerHTML += `<center><h3>Sos un ${character}</h3></center>`;
}