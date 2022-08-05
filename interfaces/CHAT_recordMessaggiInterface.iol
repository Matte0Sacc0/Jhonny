
type messaggio : void {
  .testo: string
  .nome: string
  .ora: string
  .destinatario: string
  .private: bool
}

interface CHAT_recordMessaggiInterface {
  RequestResponse:scrivi( messaggio )( bool )
  RequestResponse: leggi( void )( bool )
}