
include "console.iol"
include "interfaces/CHAT_InBoxInterface.iol"
include "interfaces/CHAT_LocalInterface.iol"
include "interfaces/LOG_ServiceInterface.iol"
include "file.iol"
include "interfaces/FILE_HistoryInterface.iol"
include "string_utils.iol"
include "time.iol"

execution { concurrent }

inputPort InBox {
  Location: LOCATION
  Protocol: sodep
  Interfaces: CHAT_InBoxInterface
}

outputPort LocalServices {
  interfaces: CHAT_LocalInterface
  Location: "socket://localhost:2000"
  Protocol: sodep
}

outputPort FileService {
  Interfaces: FILE_HistoryInterface
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
  global.log.file = "CHAT_InBoxService.ol"
  with( global.log ) { .text = "Avvio_CHAT_InBoxService"; .step = "init" }
  log
}

main {
  //metodo per decriptare il messaggio prima di farlo visualizzare attraverso "showMessageLocal@LocalServices"
  [ showMessage( message ) ] { 
    // lancio chiamata per decriptare il messaggio 
    if ( message.private ) {
      decript@LocalServices( message )( responseDecript )

      if( responseDecript.checkSign ) {
        showMessageLocal@LocalServices( responseDecript )
      }
      else {
        print@Console( "E' arrivato un messaggio, ma non e' correttamente firmato" )() 
      }
    }
    else {
      decript@LocalServices( message ) ( responseDecript )
      showMessageLocal@LocalServices( responseDecript )
    }

    //LOG Utilizzo Serivzio
    with( global.log ) { .text = "Visualizzazione Messaggio"; .step = "showMessage : main" }
    log
  }
}
