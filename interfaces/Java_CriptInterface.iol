
type sommaRequest: void {
  .chiaro: string
}

type sommaResponse: void {
  .codificato: string
}

type diffRequest: void {
  .input: void
}

type diffResponse: void {
  .pubblica: string
  .privata: string
}

type criptaRequest: void {
  .pubblica: string
  .messaggio: string
}

type criptResponse: void {
  .criptato: string
}

type deRequest : void {
  .privata: string
  .messaggio: string
}

type deResponse: void {
  .de: string
}

type firmaRequest: void {
  .chiavePrivata: string
  .inchiaro: string
}

type firmaResponse: void {
  .firmato: string
}

type verifcaRequest: void {
  .chiavePubblica: string
  .inChiaro: string
  .firma: string
}

type verificaResponse: void {
  .result: bool
}

interface Java_CriptInterface {
  RequestResponse: somma( sommaRequest )( sommaResponse )
  RequestResponse: differenza( diffRequest )( diffResponse )
  RequestResponse: moltiplica( criptaRequest )( criptResponse )
  RequestResponse: de( deRequest )( deResponse )
  RequestResponse: firma( firmaRequest )( firmaResponse )
  RequestResponse: check( verifcaRequest )( verificaResponse )
}