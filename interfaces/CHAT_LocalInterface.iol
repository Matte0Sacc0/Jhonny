
interface CHAT_LocalInterface {
  OneWay: showMessageLocal      
  RequestResponse:
    createNetwork,
    enableWelcomeService,
    manageJoin,
    askKeys,
    decript,
    UsersList,
    shaLocal,
    sendMessage    
}