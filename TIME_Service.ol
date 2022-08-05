
include "interfaces/TIME_ServiceInterface.iol"
include "interfaces/LOG_ServiceInterface.iol"
include "string_utils.iol"
include "time.iol"
include "console.iol"
include "file.iol"

execution { concurrent }

inputPort TimeService {
  Location: "local"
  Protocol: sodep
  Interfaces: TIME_ServiceInterface
}

init {
  getTimeZone
}

//Metodo per ricevere le coordinate temporali attuali
define getTimeZone {
  synchronized( timeZoneLock ) {    
    request.filename = "time_zone.txt"
    readFile@File( request )( response )
    global.timeZone = response
  }
}

main {
  //Metodo per ricevere le coordinate temporali attuali
  [ getTimeStamp()( responseTimeStamp ) {
    getCurrentTimeMillis@Time()( responseTimeStamp )
  }]

  //Metodo per impostare la Time Zone Desiderata
  [ setTimeZone( TZ ) ] {
    synchronized( timeZoneLock ) {
      global.timeZone = TZ
      writeFile@File( {
        filename = "time_zone.txt"
        append = 0
        content = TZ
      })()
      sleep@Time( 1000 )()
    }
  }

  [ getTimeString()( responseTimeString ) {
    getCurrentTimeMillis@Time()( CurrentTimeMillis )
    CurrentTimeMillis = CurrentTimeMillis + ( int( global.timeZone ) ) * 3600000
    hh = ( ( CurrentTimeMillis / ( 60000 * 60 ) ) % 24 )
    if ( hh < 10 ) { hh = "0" + hh }
    mm = ( ( CurrentTimeMillis / 60000 ) % 60 )
    if ( mm < 10 ) { mm = "0" + mm }
    ss = ( ( CurrentTimeMillis / 1000 ) % 60 )
    if ( ss < 10 ) { ss = "0" + ss }  
    
    responseTimeString = "[" + hh + ":" + mm + ":" + ss + "]" 
  }]

  /* [ checkTime(  )( execResponse ) {
    execRequest = "curl";
    with( execRequest ){
          .args[0] = "http://worldclockapi.com/api/json/est/now"
    };
    exec@Exec( execRequest )( execResponse )
    //println@Console(execResponse)()
    }]*/
}