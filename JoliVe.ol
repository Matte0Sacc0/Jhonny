
include "console.iol"
include "runtime.iol"
include "string_utils.iol"
include "time.iol"
include "ui/swing_ui.iol"

include "interfaces/TIME_ServiceInterface.iol"
include "interfaces/CHAT_JoinInterface.iol"
include "interfaces/CHAT_LocalInterface.iol"
include "interfaces/JavaServiceInterface.iol"
include "interfaces/LOG_ServiceInterface.iol"
include "interfaces/CHAT_DBInterface.iol"

outputPort Join {
  Interfaces: CHAT_JoinInterface
  Protocol: sodep
}

outputPort LocalServices {
  Interfaces: CHAT_LocalInterface
  Location: "socket://localhost:2000"
  Protocol: sodep
}

outputPort TimeService {
  Interfaces: TIME_ServiceInterface
}

outputPort JavaServiceOutputPort {
  Interfaces: JavaServiceInterface
}

outputPort LogService {
  Interfaces: LOG_ServiceInterface
  Location: "socket://localhost:2001"
  Protocol: sodep
}

outputPort DBManage {
  Interfaces: CHAT_DBInterface
  Location: "socket://localhost:2015"
  Protocol: sodep
}

embedded {
  Jolie: "TIME_Service.ol" in TimeService
}

embedded {
  Java: "Jhonny.IPJava" in JavaServiceOutputPort
}

constants {
  WelcomePort = 9999,
  ListenPort  = 9900,
  StartRoom = "Public"
}

define log {
  getCurrentTimeMillis@Time()( global.log.time )   
  writeLogInfo@LogService( global.log )()
}

//Modifica il fuso orario
define timeZone {
   //LOG Inizializzazione Servizio
  if ( roundtimeZone == 0 ) {
    with( global.log ) { .text = "Inizializzazione"; .step = "timeZone" }
    log
    roundtimeZone++
  }
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Modifica Fuso Orario : ..."; .step = "timeZone" }
  log

  getTimeString@TimeService()( TimeSystem )
  showYesNoQuestionDialog@SwingUI( "Orario sistema: " + TimeSystem + "\n vuoi impostare nuovo fuso orario?" )( responseTime );
  if( responseTime == 0 ) {
    showInputDialog@SwingUI( "Imposta nuovo fuso (+3, -2)" )( settedTime );
      while( settedTime != "-12" && settedTime != "-11" && settedTime != "-10" && settedTime != "-9" && settedTime != "-8" && settedTime != "-7" && settedTime != "-6" && settedTime != "-5" && 
          settedTime != "-4" && settedTime != "-3" && settedTime != "-2" && settedTime != "-1" && settedTime != "0" && settedTime != "+1" && settedTime != "+2" && settedTime != "+3" && 
          settedTime != "+4" && settedTime != "+5" && settedTime != "+6" && settedTime != "+7" && settedTime != "+8" && settedTime != "+9" && settedTime != "+10" && settedTime != "+11" && 
          settedTime != "+12" ) {
        showMessageDialog@SwingUI( "FUSO ORARIO INSERITO NON VALIDO" )();
        showInputDialog@SwingUI( "Imposta nuovo fuso (+3, -2)" )( settedTime )
      }
    setTimeZone@TimeService( settedTime )
    timeZone
  }

  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Modifica Fuso Orario : Modificato"; .step = "timeZone" }
  log
}

//Richiesta inserimento username
define inputUsername {
  //LOG Inizializzazione Servizio
  with( global.log ) { .text = "Inizializzazione : Creazione utente ..."; .step = "inputUsername" }

  showInputDialog@SwingUI( "\nInserire Nickname: " )( messageUser );
  while( messageUser == "" ) {
    showMessageDialog@SwingUI( "IMPOSSIBILE INSERIRE NICKNAME VUOTO" )();
    showInputDialog@SwingUI( "\nInserire Nickname: " )( messageUser )
  }
  ID.username = messageUser
  ID.WelcomePort = WelcomePort
  ID.ListenPort = ListenPort
  ID.Room = StartRoom

  println@Console()()

  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Utente Creato"; .step = "inputUsername" }
  log 
}

//rilevamento IP
define getIP {
  //LOG Inizializzazione Servizio
  with( global.log ) { .text = "Inizializzazine : Acquisizione IP"; .step = "getIP" }
  log
  
  request.message = "Avviato!";
  getIP2@JavaServiceOutputPort( request )( response )
  ID.myIP =   response.reply;
  //ID.myIP = "25.87.27.43" //IP hamachi x test, commentare se in LAN
  println@Console( "Il mio IP rilevato: " + response.reply )()
  println@Console( "Il mio IP utilizzato: " + ID.myIP )()
  MyLocation = "socket://" + ID.myIP + ":" + ListenPort
  ID.myToken = ID.myIP  //si definisce il Token come il proprio IP
  
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "IP stanza Acquisito"; .step = "getIP" }
  log
}

//Embedding Servizio "CHAT_LocalServices.ol"
define enableLocalService {    
  //LOG Inizializzazione
  with( global.log ) { .text = "Embedding : ..."; .step = "enableLocalService" }
  log
  
  with( emb ) { .filepath = "-C LOCATION=\"socket://localhost:2000\" CHAT_LocalServices.ol"; .type = "Jolie" };
  loadEmbeddedService@Runtime( emb )()

  //LOG Utilizzo servizio
  with( global.log ) { .text = "Embedding : Completato"; .step = "enableLocalService" }
  log
}

define menu {
  //LOG Inizializzazione Servizio
  if ( roundMenu == 0 ) {
    with( global.log ) { .text = "Inizializzazione"; .step = "menu" }
    log
    roundMenu++
  }
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Visualizzazione Menu : ..."; .step = "menu" }
  log
  
  showMessageDialog@SwingUI( "\n   MENU':\n
-------------------------------------------------------------------------------------\n
  . digita '#List' : Lista utenti\n
  . digita '#Time' : Settare il fuso orario\n
  . digita '@<numero utente>' : Scrivere in privato (es. @12)\n
  . digita '@9999' : Tornare a scrivere a tutta la room\n
  . digita '#Exit' : Chiudere il programma\n
-------------------------------------------------------------------------------------")();
  
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Visualizzazione Menu : Visualizzato"; .step = "menu" }
  log
}

//Stamp lista Utenti connessi
define showList {
  //LOG Inizializzazione Servizio
  if ( roundShowList == 0 ) {
    with( global.log ) { .text = "Inizializzazione"; .step = "showList" }
    log
    roundShowList++
  }
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Visualizzazione Lista Utenti : ..."; .step = "showList" }
  log 
  
  userList@DBManage()( userlList )
  global.list = null 
  global.list << userlList
  
  temp = 0
  tree = null
  for ( i = 0, i <# global.list.item, i++ ) {
    number = global.list.item[i]
    user = global.list.item[i].user
    active = global.list.item[i].active
    location = global.list.item[i].location
    if ( active ) { tree = tree + "  .@" + number + " - " + user + " - " + location + "\n" }
  }
 
  tree = tree + "  .@9999 - Invia a tutti (prefedinito)"
  showMessageDialog@SwingUI( "Elenco utenti Connessi:\n" + tree )();

  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Visualizzazione Lista Utenti : Visualizzata"; .step = "showList" }
  log 
}

//Maschera Selezione destinatario messaggio
define selectDest {
  //LOG Inizializzazione Servizio
  if ( roundSelDest == 0 ) {
    with( global.log ) { .text = "Inizializzazione"; .step = "selectDest" }
    log
    roundSelDest++
  }
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Selezione Destinatario : ..."; .step = "selectDest" }
  log

  tempDestination << global.destination

  split.regex = "@"
  split = input
  split@StringUtils( split )( responseSplit )
  value = int( responseSplit.result[1] )
  
  if ( value == "9999" ) { //Destinazinoe Pubblica
    global.destination = 9999
    global.destination.user = "Public"
    global.destination.keyPublic = 0

    showInputDialog@SwingUI( "\nMessage to All: " )( inputMsg );
    if ( inputMsg == "" ) {
      showMessageDialog@SwingUI( "IMPOSSIBILE INVIARE MESSAGGI VUOTI" )()
    }
    else {
      getTimeString@TimeService()( timeSend );
      //Invio Messaggio Pubblico
      sendMessage@LocalServices( { .token = ID.myToken, .text = inputMsg, .username = ID.username, .time = timeSend, .dest = global.destination, .keyPublic = global.destination.keyPublic } )();
      println@Console( "To Public -> " + timeSend + " - " + ID.username  + " : " + inputMsg )()
    }
  } 

  else { //Destinazione privata
    checkuser@DBManage( global.list.item[value].token2 )( active )
    global.destination.token.active = active
    
    if( active == false ) {
      showMessageDialog@SwingUI( "***** ERRORE SELEZIONE DESTINATARIO : DESTINATARIO NON VALIDO *****" )()
      showList
    }
    else {
      global.destination = global.list.item[value].location
      global.destination.user = global.list.item[value].user
      global.destination.keyPublic = global.list.item[value].keyPublic
      global.destination.token = global.list.item[value].token2

      if( global.destination == null || global.destination == MyLocation || global.destination.keyPublic == null || global.destination.active == false ) {
        showMessageDialog@SwingUI( "***** ERRORE SELEZIONE DESTINATARIO : DESTINATARIO NON VALIDO *****" )()
        global.destination << tempDestination
        with( global.log ) { .text = "***** ERRORE SELEZIONE DESTINATARIO : DESTINATARIO NON VALIDO *****"; .step = "selectDest" }
        log
      }
      else {
        showInputDialog@SwingUI( "\nMessage to " + global.destination.user + ":")( inputMsg );
        checkuser@DBManage( global.list.item[value].token2 )( active )
        global.destination.token.active = active
        if( active == false ) {
          showMessageDialog@SwingUI( "***** ERRORE SELEZIONE DESTINATARIO : IL DESTINATARIO SI E' APPENA DISCONNESSO *****" )()
          showList
        }
        if ( inputMsg == "" ) {
          showMessageDialog@SwingUI( "IMPOSSIBILE INVIARE MESSAGGI VUOTI" )()
        }
        else {
          getTimeString@TimeService()( timeSend );
          println@Console( "To " + global.destination.user + " -> " + timeSend + " - " + ID.username  + " : " + inputMsg )();
          sendMessage@LocalServices( { .token = ID.myToken, .text = inputMsg, .username = ID.username, .time = timeSend, .dest = global.destination, .keyPublic = global.destination.keyPublic } )()
        }
      }
    }
  }
  //Reset destinazione dopo invio messaggio privato
  global.destination = 9999
  global.destination.user = "Public"
  global.destination.keyPublic = 0

  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Selezione Destinatario : Selezionato"; .step = "selectDest" }
  log
}

//Embedding Servizio "CHAT_DBManage.ol"
define enableDBService { 
  //LOG Inizializzazione
  with( global.log ) { .text = "Embedding : ..."; .step = "enableDBService" }
  log
  
  with( emb ) { .filepath = "CHAT_DBManage.ol"; .type = "Jolie" };   
  loadEmbeddedService@Runtime( emb )()

  //LOG Utilizzo servizio
  with( global.log ) { .text = "Embedding : Completato"; .step = "enableDBService" }
  log
}

//Embedding Servizio "LOG_Service.ol"
define enableLogService {  
  with( emb ) { .filepath = "LOG_Service.ol"; .type = "Jolie" };   
  loadEmbeddedService@Runtime( emb )()
  
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Embedding : Completato"; .step = "enableLogService" }
  log
}

//***************** CONNECT NETWORK *********************
//*******************************************************
//Servizio per connessione a rete P2P esistente
define connectNetwork {
  //LOG Inizializzazione servizio
  if ( roundconnectNetwork == 0 ) {
    with( global.log ) { .text = "Inizializzazione"; .step = "connectNetwork" }
    log
    roundconnectNetwork++
  }
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Connessione a Network : ..."; .step = "connectNetwork" }
  log

  //gestione eccezioni  
  scope( fault_conn ) {
    //setNextTimeout@Time ( 5000 )
    install( IOException => println@Console( "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE COLLEGARSI ALL'IP INSERITO *****\n IL PROGRAMMA E' TERMINATO IN QUANTO NON E' POSSIBILE CONNETTERSI ALL'IP INSERITO" )()
      with( global.log ) { .text = "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE COLLEGARSI ALL'IP INSERITO *****"; .step = "connectNetwork" }
      log
      halt@Runtime()()
    );

    install( TimeOut => println@Console( "***** ERRORE 'TIME OUT' : IMPOSSIBILE COLLEGARSI ALL'IP INSERITO *****\n IL PROGRAMMA E' TERMINATO IN QUANTO NON E' POSSIBILE CONNETTERSI ALL'IP INSERITO" )()
      with( global.log ) { .text = "***** ERRORE 'TIME OUT' : IMPOSSIBILE COLLEGARSI ALL'IP INSERITO *****"; .step = "connectNetwork" }
      log
      halt@Runtime()()
    );
   
    println@Console( "\nconnecting..." + global.response.text )()
    requestJoin.username = username
    Join.location = "socket://" + args [0] + ":" + WelcomePort    //assegnazione dinamica della location della porta Join
    println@Console( "send request joinNetwork to: " + Join.location )()
    ID.welcomeEnable = false 
  
    //Connessione a rete P2P
    joinNetwork@Join( ID )( responseJN )
    //Aggiorno il mio DB con il DB ricevuto dal Peer a cui mi sono connesso
    mergeDB@DBManage( responseJN )( update )

    global.myDB  << responseJN
  };
  
  foreach( u : global.myDB.tokens ) {
    //setNextTimeout@Time ( 5000  )
    if( global.myDB.tokens.( u ).ip != args[0] && global.myDB.tokens.( u ).ip != ID.myIP && global.myDB.tokens.( u ).active == true ) { 
      if( global.myDB.tokens.( u ).ip  != null ) {
        scope( fault_conn ) {
          //setNextTimeout@Time( 5000 )
          install ( IOException => println@Console( "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE COLLEGARSI ALL'IP INSERITO ***** " + global.myDB.tokens.( u ).ip )()
            with( global.log ) { .text = "***** ERRORE 'FAULT CONNECTION' : IMPOSSIBILE COLLEGARSI ALL'IP INSERITO *****"; .step = "connectNetwork" }
            log
            global.myDB.tokens.( u ).avable = false 
          );

          install ( TimeOut => println@Console( "***** ERRORE 'TIME OUT' : IMPOSSIBILE COLLEGARSI ALL'IP INSERITO *****" + global.myDB.tokens.( u ).ip )()
            with( global.log ) { .text = "***** ERRORE 'TIME OUT' : IMPOSSIBILE COLLEGARSI ALL'IP INSERITO *****"; .step = "connectNetwork" }
            log
            global.myDB.tokens.( u ).avable = false
          );

          requestJoin.username = username
          Join.location = "socket://" + global.myDB.tokens.( u ).ip + ":" + WelcomePort
          println@Console( "Send request joinNetwork to: " + Join.location )()
          
          ID.welcomeEnable = false 
          joinNetwork@Join( ID )( responseJN )  
          responseJN  << global.myDB
          mergeDB@DBManage( responseJN )( responseUD )
        }
      }
    }
  }
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Connessione a Network : Avvenuta"; .step = "connectNetwork" }
  log
}

//****************** NEW NETWORK ********************
//***************************************************
//Metodo per lanciare la creazione di una nuova Rete P2P
define newNetwork {
  //LOG Inizializzazione servizio
  if ( roundnewNetwork == 0 ) {
    with( global.log ) { .text = "Inizializzazione"; .step = "newNetwork" }
    log
    roundnewNetwork++
  }
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Creazione Nuovo Network : ..."; .step = "newNetwork" }
  log
  
  //gestione eccezioni  
  scope( exception ) {    
    install ( IOException => println@Console( "***** ERRORE 'IOExceptioin' : IMPOSSIBILE CREARE NUOVA RETE *****" )()
      with( global.log ) { .text = "***** ERRORE 'IOExceptioin' : IMPOSSIBILE CREARE NUOVA RETE *****"; .step = "newNetwork" }
      log
      halt@Runtime()()
    );

    install ( TimeOut => println@Console( "***** ERRORE 'TimeOut' : IMPOSSIBILE CREARE NUOVA RETE *****" )()
      with( global.log ) { .text = "***** ERRORE 'TimeOut' : IMPOSSIBILE CREARE NUOVA RETE *****"; .step = "newNetwork" }
      log
      halt@Runtime()()
    );

    install ( CloseException => halt@Runtime()() )
    createNetwork@LocalServices( ID )( responseCN )
  }
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Creazione Nuovo Network : Creato"; .step = "newNetwork" }
  log
}

//Metodo richiesta chiavi per crittografia
define generatedKey {
  //LOG Inizializzazione Servizio
  with( global.log ) { .text = "Inizializzazione : Generazione Chiavi : ..."; .step = "generatedKey" }
  
  //Richiesta chiave pubblica/privata
  requestKeys = null
  askKeys@LocalServices( requestKeys )( responseKeys )
  ID.keyPublic = responseKeys.pubblica 
  
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Generazione Chiavi : Generate"; .step = "generatedKey" } 
}

//Servizio abilitazione Chat: abilita InBox service, per gestire la ricezione dei messaggi
define enableChat {
  //LOG Inizializzazione Servizio
  with( global.log ) { .text = "Avvio 'CHAT_InBoxService.ol' : ..."; .step = "enableChat" }
  log

  //gestione eccezioni
  install( IOExceptio => println@Console( "***** ERRORE 'ENABLE CHAT' : FALLITA CREAZIONE NUOVA CHAT *****" )()
    with( global.log ) { .text = "***** ERRORE 'ENABLE CHAT' : FALLITA CREAZIONE NUOVA CHAT *****"; .step = "enableChat" }
    log
  );

  InboxLocation = "socket://" + ID.myIP + ":" + ListenPort
  with( Inbox ) { .filepath = "-C LOCATION=\"" + InboxLocation + "\" CHAT_InBoxService.ol"; .type = "Jolie" };
  loadEmbeddedService@Runtime( Inbox )()

  //LOG Utilizzo Servizio
  with( global.log ) { .text = "Avvio 'CHAT_InBoxService.ol' : Avviato"; .step = "enableChat" }
  log
}

//Metodo avvio servizio gestione richieste connesione a rete P2P: CHAT_WelcomeService
define enableWelcomeServiceJolive {
  //LOG Utilizzo Servizio
  with( global.log ) { .text = "roundenableWelcomeServiceJolive' : ..."; .step = "enableWelcomeServiceJolive"
  }
  log
  
  enableWelcomeService@LocalServices( ID )( responseW )

  //LOG Utilizzo Servizio
  with( global.log ) { .text = "roundenableWelcomeServiceJolive' : Avviato"; .step = "enableWelcomeServiceJolive" }
  log
}

init {
  print@Console( "Avvio...   :   " )()
  global.log.file = "JoliVe.ol"
  enableLogService
  enableDBService
  //LOG Inizializzazione
  with( global.log ) { .text = "Inizializzazione"; .step = "init" }
  log

  if ( #args != 1 ) {  // controllo sintassi di lancio
    println@Console( "Usare: jolie JoliVe.ol <IP destinazione> \t/ per connettersi ad un network esistente " )();
    println@Console( "Usare: jolie JoliVe.ol new \t\t\t/ per creare nuovo network " )()
    halt@Runtime()()  // esce dal programma (evita errori con parametri non definiti)                       
  }
  else {  //inizio operazioni preliminari comuni
    enableLocalService
    getIP
    generatedKey
    inputUsername
    global.destination = 9999 //imposto la destinazione a tutta la stanza e non al singolo utenti
    global.destination.user = "Public"
  }

  if( args[0] != "new" ) { connectNetwork }     // LANCIO TIPO 1: se arg[0] != "new -> si unisce a network esistente inviando richiesta a IP indicato arg[0]
  else { newNetwork }                           // LANCIO TIPO 2: se arg[0] = "new" -> crea nuova chat

  //operazioni comuni di inizializzazione finale
  enableWelcomeServiceJolive
  enableChat

  //messaggio di entrata nell chat
  getTimeString@TimeService()( timeSend );
  sendMessage@LocalServices( { .token = ID.myToken, .text = "ENTRATO", .username = ID.username, .time = timeSend, .dest = global.destination , .keyPublic = 0,  } )()
  
  showList

  //LOG Inizializzazione
  with( global.log ) { .text = "Inizializzato"; .step = "init" }
  log
}

main {
  //Variabili per LOG
  roundMenu = 0
  roundSelDest = 0
  roundShowList = 0
  roundconnectNetwork = 0
  roundnewNetwork = 0
  roundtimeZone = 0

  //Setting fuso orario
  setTimeZone@TimeService( 2 )

  //Ingresso nel processo principale del programma
  while( cmd != "exit" && cmd != "" ) {
    showInputDialog@SwingUI( "\nDigitare '#Menu' per menu'\nDigitare '#List' per lista utenti connessi\nDigitare (messaggio) per inviare un messaggio pubblico:\n" )( input );
    input.end = 1
    input.begin = 0
    substring@StringUtils( input )( responseSubstring )

    //Selezione Operazioni "MENU"
    if ( responseSubstring == "@" ) { selectDest }
    else if ( input == "#Menu" || input == "#menu" || input == "#m" || input == "#M" ) { menu }
    else if ( input == "#List" || input == "#list"  || input == "#l" || input == "#L") { showList }
    else if ( input == "#Time" || input == "#time"  || input == "#t" || input == "#T") { timeZone }
    else if ( input == "#Exit" || input == "#exit"  || input == "#e" || input == "#E") {
      
      //LOG Uscita dal Programma
      with( global.log ) { .text = "Terminazione processi JHONNY : ..."; .step = "main : uscita dal programma" }
      log

      verifica = "#####@@@@@"

      getTimeString@TimeService()( timeSend );
      sendMessage@LocalServices( { .token = ID.myToken, .text = verifica, .username = ID.username, .time = timeSend, .dest = "9999" , .keyPublic = ID.keyPublic } )();
    
      cmd = "exit"

      //LOG Uscita dal Programma
      with( global.log ) { .text = "Terminazione processi JHONNY : Terminati : Uscita Corretta"; .step = "main : uscita dal programma" }
      log

      println@Console( "\n###############" )()
      println@Console( "#             #" )()
      println@Console( "# ARRIVEDERCI #" )()
      println@Console( "#             #" )()
      println@Console( "###############\n" )()
    }

    //Invio messaggio in Chat Pubblica "Operazione di Default"
    else {
      while ( input == "" ) { //controllo su input
        showMessageDialog@SwingUI( "IMPOSSIBILE INVIARE MESSAGGI VUOTI" )();
        showInputDialog@SwingUI( "\nDigitare '#Menu' per menu'\nDigitare '#List' per lista utenti connessi\nDigitare (messaggio) per inviare un messaggio pubblico:\n" )( input )
      }
      getTimeString@TimeService()( timeSend );
      println@Console( "To Public -> " + timeSend + " - " + ID.username  + " : " + input )();
      sendMessage@LocalServices( { .token = ID.myToken, .text = input, .username = ID.username, .time = timeSend, .dest = "9999" , .keyPublic = 0 } )()
    }
  }
}