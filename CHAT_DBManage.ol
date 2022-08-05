
include "interfaces/CHAT_DBInterface.iol"
include "interfaces/LOG_ServiceInterface.iol"
include "string_utils.iol"
include "time.iol"
include "console.iol"
include "file.iol"

execution { concurrent }

inputPort DBmanage {
  Location: "socket://localhost:2015"
  Protocol: sodep
  Interfaces: CHAT_DBInterface
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

//metodo per aggiungere un utente al database
define addUser {
  //LOG Inizializzazione servizio
  if ( roundAddUser == 0 ) {
    with( global.log ) { .text = "Inizializzazione"; .step = "addUser" }
    log
    roundAddUser++
  }
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Aggiunta Nuovo Utente al DataBase : ..."; .step = "addUser" }
  log
  
  synchronized( DBLock ) {
    locationChat = "socket://" + requestAdd.myIP +  ":" + requestAdd.ListenPort
    token = requestAdd.myIP
    userPresentOnDB = false
    foreach( u : global.chatDB.tokens ) {
      if ( requestAdd.myIP == global.chatDB.tokens.( u ).ip ) {
        //println@Console( "Utente gia presente all'interno del db" )()
        undef( global.chatDB.tokens.( u ) )
      }
      i++
    }
    
    global.chatDB.tokens.( token ).user = requestAdd.username;  
    global.chatDB.tokens.( token ).location = locationChat;
    global.chatDB.tokens.( token ).keyPublic = requestAdd.keyPublic; 
    global.chatDB.tokens.( token ).room = requestAdd.Room;
    global.chatDB.tokens.( token ).ip = requestAdd.myIP;
    global.chatDB.tokens.( token ).active = true
    global.chatDB.tokens.( token ).countOffiline = 2
   
    global.chatDB.rooms.( requestAdd.Room ) = true

    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Aggiunta Nuovo Utente al DataBase : Aggiunto"; .step = "addUser" }
    log
  }
}

//metodo per la comunicazione e la gestione della lista di utenti presenti nel database
define userList {
  synchronized( DBLock ) {
    //LOG Inizializzazione servizio
    if ( roundUserList == 0 ) {
      with( global.log ) { .text = "Inizializzazione"; .step = "userList" }
      log
      roundUserList++
    }
    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Creazione Lista Utenti da DataBase : ..."; .step = "userList" }
    log
    
    list = null
    
    i = 0
    foreach( u : global.chatDB.tokens ) {
      list.item[ i ] = i
      list.item[ i ].user = global.chatDB.tokens.( u ).user
      list.item[ i ].location = global.chatDB.tokens.( u ).location
      list.item[ i ].keyPublic = global.chatDB.tokens.( u ).keyPublic
      list.item[ i ].active = global.chatDB.tokens.( u ).active
      list.item[ i ].token1 =  global.chatDB.tokens.( u )
      list.item[ i ].token2 =  u
      i++
    }

    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Creazione Lista Utenti da DataBase : Creata"; .step = "userList" }
    log
  }
}

//metodo per didabilitare un utente dal database
define disableUser {
  synchronized( DBLock ) {
    //LOG Inizializzazione servizio
    if ( roundDisableUser == 0 ) {
      with( global.log ) { .text = "Inizializzazione"; .step = "disableUser" }
      log
      roundDisableUser++
    }
    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Disabilitazione Utente dal DataBase : ..."; .step = "disableUser" }
    log

    userPresentOnDB = false
    foreach( u : global.chatDB.tokens ) {
      if ( requestLocation == global.chatDB.tokens.( u ).location || requestLocation == global.chatDB.tokens.( u ).keyPublic ) {
        userPresentOnDB = true
        global.chatDB.tokens.( u ).active = false
        temp = u
      }
      i++
    }

    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Disabilitazione Utente dal DataBase : Disabilitato"; .step = "disableUser" }
    log
  }
}

//metodo per riabilitare un utente che si ricollega al database
/*
define enableUser {
  synchronized( DBLock ) {
    //LOG Inizializzazione servizio
    if ( roundEnableUser == 0 ) {
      with( global.log ) { .text = "Inizializzazione"; .step = "enableUser" }
      log
      roundEnableUser++
    }
    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Abilitazione Utente DataBase : ..."; .step = "enableUser" }
    log

    userPresentOnDB = false 
    foreach( u : global.chatDB.tokens ) {
      if ( requestIP == global.chatDB.tokens.( u ).ip ) {
        //println@Console( "Untente ONLINE " )()
        userPresentOnDB = true
        global.chatDB.tokens.( u ).active = true
      }
      i++
    }
    
    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Abilitazione Utente DataBase : Abilitato"; .step = "enableUser" }
    log 
  }
}
*/

init {
  global.log.file = "CHAT_DBManage.ol"
  with( global.log ) { .text = "Avvio_CHAT_DBManage"; .step = "init" }
  log

  //variabili per i LOG
  roundAddUser = 0
  roundUnionDB = 0
  roundUserList = 0
  roundDisableUser = 0
  //roundEnableUser = 0
}

main {
  [ addUser( requestAdd )( response ) {
    addUser
    response << global.chatDB    
  }]

  [ checkuser( token )( active ) {
    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Controllo Presenza Utente nel Database : ..."; .step = "checkuser" }
    log

    synchronized( DBLock ) {
      check = global.chatDB.tokens.( token ).active
      if ( check == false || check == null ) {
        active = false
      }
      else { active = true }
    }

    //LOG Utilizzo Servizio
    with( global.log ) { .text = "Controllo Presenza Utente nel Database : Controllato"; .step = "checkuser" }
    log
  }]

  [ disableUser( token )( active ) {
    synchronized( DBLock ) {
      token = message.token
      global.chatDB.tokens.( token ).active = false
    }      
  }]

  [ disableUserKeyPublic( keyPublic )( active ) {
    requestLocation = keyPublic
    synchronized( DBLock ) {
      disableUser
    }
  }]
  
  /*
  [ enableUser( token )( active ) {
    synchronized( DBLock ) {
      global.chatDB.tokens.( token ).active = true
    }
  }]
  */

  [ mergeDB( requestDB )( response ) {
    //LOG Utilizzo Serivzio
    with( global.log ) { .text = "Merging DataBase : ..."; .step = "mergeDB" }
    log

    synchronized( DBLock ) {
      global.chatDB << requestDB
      response = true
    }

    //LOG Utilizzo Serivzio
    with( global.log ) { .text = "Merging DataBase : Merged"; .step = "mergeDB" }
    log
  }]

  [ userList( requestDB )( responseList ) {
    userList
    responseList << list
  }]

  [ returnDB()( db ) {
    //LOG Utilizzo Serivzio
    with( global.log ) { .text = "Comunicazione DataBase : ..."; .step = "returnDB" }
    log
    
    db << global.chatDB

    //LOG Utilizzo Serivzio
    with( global.log ) { .text = "Comunicazione DataBase : Comunicato"; .step = "returnDB" }
    log
  }]
}
