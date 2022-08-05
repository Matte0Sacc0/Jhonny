
include "interfaces/FILE_HistoryInterface.iol"
include "file.iol"
include "console.iol"
include "string_utils.iol"
include "time.iol"

execution { concurrent }

inputPort FileService {
  Location: "local"
  Protocol: sodep
  Interfaces: FILE_HistoryInterface
}

init {
  global.log.file = "FILE_History.ol"
  global.index = 0
}

main {
  //metodo per scrivere la cronologia dei messaggi su FIle
  [ writeHistory( message )] {
    synchronized( synchWriteHistory ) {      
      getCurrentDateValues@Time( request )( responsegetDate )
      fileName = responsegetDate.year + "-" + responsegetDate.month + "-" + responsegetDate.day +  "-" + "History.json"
      
      writeFile@File( {
        filename = "LOG_JHONNY/HISTORY/" + fileName
        format = "json"
        append = 1
        content << {
          note << {
            id = global.index
            text = message.text
            time = message.time
            username = message.username
          }
        }
      } )()

      global.index++
      sleep@Time( 1000 )()
    }
  }
}
