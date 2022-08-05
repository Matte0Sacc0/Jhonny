
include "interfaces/CHAT_LocalInterface.iol"
include "interfaces/CHAT_InBoxInterface.iol"
include "interfaces/CHAT_DBInterface.iol"
include "interfaces/Java_CriptInterface.iol"
include "interfaces/CHAT_recordMessaggiInterface.iol"
include "interfaces/FILE_HistoryInterface.iol"
include "interfaces/LOG_ServiceInterface.iol"
include "ui/swing_ui.iol"

include "console.iol"
include "string_utils.iol"
include "runtime.iol"
include "time.iol"
include "file.iol"

execution { concurrent }  

inputPort LocalServices {
  Location:"socket://localhost:2000"
  Protocol: sodep
  Interfaces: CHAT_LocalInterface
}

outputPort Send {
  Protocol: sodep
  Interfaces: CHAT_InBoxInterface
}

outputPort DBManage {
  Interfaces: CHAT_DBInterface
  Location: "socket://localhost:2015"
  Protocol: sodep
}

outputPort JavaCript {
  Interfaces: Java_CriptInterface
}

outputPort FileService {
  Interfaces: FILE_HistoryInterface
}

outputPort LogService {
  interfaces: LOG_ServiceInterface
  Location: "socket://localhost:2001"
  Protocol: sodep
}

embedded {
  Java: "Basta.Somma" in JavaCript
}

embedded {
  Jolie: "FILE_History.ol" in FileService
}

init {
  global.log.file = "CHAT_LocalService.ol"
  with( global.log ) { .text = "Avvio_CHAT_LocalService"; .step = "init" }
  log
  global.chatDB.lock = false
}
 
define log {
  getCurrentTimeMillis@Time()( global.log.time )   
  writeLogInfo@LogService( global.log )()
}

define sendMessagePublic {
  //LOG Utilizzo servizio
  with( global.log ) { .text = "Invio Messaggio Pubblico : ..."; .step = "sendMessagePublic" }
  log

  // richiesta DB aggiornato
  global.chatDB = null 
  returnDB@DBManage()( db )
  global.chatDB << db

  // preparazione il messaggio 
  firmaRequest.inchiaro = requestSM.text
  firmaRequest.chiavePrivata = global.Key.privata
  firma@JavaCript( firmaRequest )( firmato )
          
  with( message ) {
    .text = requestSM.text;
    .username = requestSM.username;
    .time = requestSM.time;
    .signature = firmato.firmato;
    .private = false
    .publicKeySender = global.Key.pubblica
  };
 
  foreach( u : global.chatDB.tokens ) {
    if ( requestSM.token != u && global.chatDB.tokens.( u ).active == true ) {
      scope( fault_conn ) {
        //setNextTimeout@Time( 5000 )
        install ( IOException => println@Console( "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE INVIARE MESSAGGI A QUESTO UTENTE : " + global.chatDB.tokens.( u ).user + " *****" )()
          with( global.log ) { .text = "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE INVIARE MESSAGGI A QUESTO UTENTE : " + global.chatDB.tokens.( u ).user + " *****"; .step = "sendMessagePublic" }
          log
          global.chatDB.tokens.( u ).active = false
        );

        install ( TimeOut => println@Console( "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE INVIARE MESSAGGI A QUESTO UTENTE : " + global.chatDB.tokens.( u ).user + " *****" )()
          with( global.log ) { .text = "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE INVIARE MESSAGGI A QUESTO UTENTE : " + global.chatDB.tokens.( u ).user + " *****"; .step = "sendMessagePublic" }
          log
          global.chatDB.tokens.( u ).active = false
        );
        
        if( global.chatDB.tokens.( u ).active ) {
          Send.location = global.chatDB.tokens.( u ).location;
          showMessage@Send( message )

          //LOG Utilizzo servizio
          with( global.log ) { .text = "Invio Messaggio Pubblico : Inviato"; .step = "sendMessagePublic" }
          log
        }
      }
      mergeDB@DBManage( global.chatDB )( response )
    }
  }
}

main {
  [ createNetwork( requestAdd )( responseDB ) {
    //LOG Utilizzo Serivzio
    with( global.log ) { .text = "Creazione Network"; .step = "createNetwork" }
    log
   
    addUser@DBManage( requestAdd )( responseDB )   

    responseDB << global.chatDB
    //ID.myToken = global.chatDB.generatedToken //mi serve quando invio a tutti DB aggiornato
  }]

  [ enableWelcomeService( requestW )( responseW ) {  // Abilita Welcome service
    locationWelcome = "socket://" + requestW.myIP +  ":" + requestW.WelcomePort
    with( emb ) { .filepath = "-C LOCATION=\"" + locationWelcome + "\" CHAT_WelcomeService.ol"; .type = "Jolie" };        
    loadEmbeddedService@Runtime( emb )()
    responseW = true
  }]

  [ manageJoin( requestAdd )( responseDB ) {  
    addUser@DBManage( requestAdd )( response );
    responseDB << response
  }]

  [ sendMessage( requestSM )( response ) {
    //LOG Utilizzo Serivzio
    with( global.log ) { .text = "Invio Messaggio : ..."; .step = "sendMessage" }
    log

    //richiesta accesso DB 
    if ( requestSM.dest == 9999 ) {
      sendMessagePublic
    }
    else {
      returnDB@DBManage()( db )
      global.chatDB << db

      Send.location = requestSM.dest
      firmaRequest.inchiaro = requestSM.text
      firmaRequest.chiavePrivata = global.Key.privata
      firma@JavaCript( firmaRequest )( firmato )
            
      //cripto messaggio + username + ora
      input.pubblica = requestSM.keyPublic //chiave public
    
      input.messaggio = requestSM.text //messaggio in chiaro, lo stampo
      requestSM.text = messaggio.nome
      moltiplica@JavaCript( input )( requestSMCript )
            
      input.messaggio = requestSM.username // username mittente, lo stampo
      requestSM.username = messaggio.nome
      moltiplica@JavaCript( input )( requestSMUser )
              
      input.messaggio = requestSM.time
      requestSM.time = messaggio.ora
      moltiplica@JavaCript( input )( requestSMtime )
      
      messaggio.destinatario = " "
      
      with( message ) {
        .text = requestSMCript.criptato;
        .username = requestSMUser.criptato;
        .time = requestSMtime.criptato;
        .signature = firmato.firmato;
        .private = true
        .publicKeySender = global.Key.pubblica
      };

      attivo = true

      scope( fault_conn ) {
        //setNextTimeout@Time ( 5000 )
        install ( IOException => println@Console( "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE INVIARE MESSAGGI A QUESTO UTENTE : " + requestSM.dest + " *****" )()
          with( global.log ) { .text = "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE INVIARE MESSAGGI A QUESTO UTENTE : " + requestSM.dest + " *****"; .step = "sendMessage" }
          log
          foreach( u : global.chatDB.tokens ) {
            if ( requestSM.dest == global.chatDB.tokens.( u ).location ) {
              println@Console( requestSM.dest + " " + global.chatDB.tokens.( u ).location )()
              global.chatDB.tokens.( u ).active = false
              attivo = false
            }
          }
        );

        install ( TimeOut => println@Console( "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE INVIARE MESSAGGI A QUESTO UTENTE : " + requestSM.dest + " *****" )()
          with( global.log ) { .text = "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE INVIARE MESSAGGI A QUESTO UTENTE : " + requestSM.dest + " *****"; .step = "sendMessage" }
          log
          foreach( u : global.chatDB.tokens ) {
            if ( requestSM.dest == global.chatDB.tokens.( u ).location ) {
              global.chatDB.tokens.( u ).active = false
              attivo = false
            }
          }
        );
        showMessage@Send( message )
      }
      mergeDB@DBManage( global.chatDB )( response )
    }

    //LOG Utilizzo Serivzio
    with( global.log ) { .text = "Invio Messaggio : Inviato"; .step = "sendMessage" }
    log
  }]

  [ askKeys( requestKeys )( responseKeys ) {
    richiesta.input = void
    differenza@JavaCript( richiesta )( resultKeys )
    responseKeys << resultKeys
    global.Key.privata = responseKeys.privata
    global.Key.pubblica = responseKeys.pubblica
  }]

  [ decript( requestDecript )( responseDecript ) {
    verifica.chiavePubblica = requestDecript.publicKeySender
    verifica.inChiaro = requestDecript.text
    verifica.firma = requestDecript.signature 
    se = requestDecript.private

    if( se ) {
      //decripta il messaggio
      input.messaggio = requestDecript.text
      input.privata = global.Key.privata
      
      de@JavaCript( input )( JavaDecriptText )
      responseDecript.text = JavaDecriptText.de
      verifica.inChiaro = JavaDecriptText.de

      //decripta l'user
      input.messaggio = requestDecript.username
      input.privata = global.Key.privata
      
      de@JavaCript( input )( JavaDecriptUser )
      responseDecript.username = "( PRIVATE ) : " + JavaDecriptUser.de
    
      //#@ l'ora
      input.messaggio = requestDecript.time
      input.privata = global.Key.privata
      
      de@JavaCript( input )( JavaDecriptTime )
      responseDecript.time = JavaDecriptTime.de

      responseDecript.keyPublic = requestDecript.publicKeySender
    }
    else {
      responseDecript.text = requestDecript.text
      responseDecript.username = requestDecript.username
      responseDecript.time = requestDecript.time
      responseDecript.keyPublic = requestDecript.publicKeySender
    }

    check@JavaCript( verifica )( boolea )
    responseDecript.checkSign = boolea.result

    with( global.log ) { .text = "Message Decript"; .step = "decript : main" }
    log 
  }]

  [ showMessageLocal( message ) ] {
    tmp = message.text
    verifica = "#####@@@@@"
   
    if ( tmp == verifica ) {
      message.text = "SONO USCITO"
      disableUserKeyPublic@DBManage( message.keyPublic )()
      returnDB@DBManage()( db )
      cmd = ""
      showMessageDialog@SwingUI( message.time + " - " + message.username  + " : " + message.text )()
    }
    else if ( tmp == "ENTRATO" ) { showMessageDialog@SwingUI( message.time + " - " + message.username  + " : " + message.text )() }
    else { 
      synchronized( showMessageLoc ) {
        println@Console( "From <- " + message.time + " - " + message.username  + " : " + message.text )()
      }
    }
    // salvo il messaggio ricevuto su file 
    writeHistory@FileService( message )
  }

  //metodo per leggere il database da file
  [ UsersList()( list ) {
    userList@DBManage()( list )
  }]

  [ shaLocal( input )( output ) {
    request.chiaro = input
    somma@JavaCript( request )( sha )
    output = sha.codificato 
  }]
}