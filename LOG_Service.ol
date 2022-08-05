
include "interfaces/LOG_ServiceInterface.iol"
include "string_utils.iol"
include "time.iol"
include "console.iol"
include "file.iol"

execution { concurrent }

inputPort LogService {
  Location: "socket://localhost:2001"
  Protocol: sodep
  Interfaces: LOG_ServiceInterface
}

//Metodo per prendere le informazioni sull'orario dal sistema
define dataTimeNow {
  getCurrentTimeMillis@Time()( responseTimeStamp )
  getDateTime@Time( responseTimeStamp )( response )
  global.now = response
}

main {
  //metodo per scrivere i LOG su FIle
  [ writeLogInfo( request )( response ) {
    synchronized( tokenFileLog ) {
      getCurrentDateValues@Time( requestDate )( responsegetDate )
      writeFile@File( {
        filename = "LOG_JHONNY/LOG/" + responsegetDate.year + "-" + responsegetDate.month + "-" + responsegetDate.day +  "-" + "LOG.json"
        format = "json"
        append = 1
        content << {
          LOG_INFO << {
            when = request.time;
            who = request.file;
            what = request.step;
            done = request.text
          }
        }
      })()
    }
  }]
}      