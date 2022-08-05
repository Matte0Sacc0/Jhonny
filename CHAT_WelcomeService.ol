
include "interfaces/CHAT_WelcomeInterface.iol"
include "interfaces/CHAT_LocalInterface.iol"
include "interfaces/LOG_ServiceInterface.iol"
include "interfaces/CHAT_DBInterface.iol"
include "console.iol"
include "time.iol"

execution { concurrent }

inputPort WelcomePort {
  Location: LOCATION
  Protocol: sodep
  Interfaces: CHAT_WelcomeInterface
}

outputPort DBManage {
  Interfaces: CHAT_DBInterface
  Location: "socket://localhost:2015"
  Protocol: sodep
}

outputPort LocalServices {
  Location: "socket://localhost:2000"
  interfaces: CHAT_LocalInterface
  Protocol: sodep
}

outputPort LogService {
  interfaces: LOG_ServiceInterface
  Location: "socket://localhost:2001"
  Protocol: sodep
}

define log {
  getCurrentTimeMillis@Time()( global.log.time )   
  writeLogInfo@LogService( global.log )()
}

init {
  global.log.file = "CHAT_WelcomeService.ol"
  with( global.log ) { .text = "Avvio_CHAT_WelcomeService"; .step = "init" }
  log
}

main {
  //metodo per gestire l'inserimento di nuovi utenti in una rete
  [ joinNetwork( request )( responseDB ) {  // Inserisce user in Database tramite adduser in localservice
    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Joining Network : ..."; .step = "joinNetwork" }
    log

    print@Console( "\nrequested join : ... " )()
    println@Console( request.username + " : " + request.myIP + "\n" )()
    requestMJ << request
    //manageJoin@LocalServices( requestMJ )( responseMJ )
    addUser@DBManage( request )( responseMJ )
    responseDB << responseMJ

    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Joining Network : Joined"; .step = "joinNetwork" }
    log
  }]
}
