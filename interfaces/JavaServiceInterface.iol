
type IPRequest: void {
  .message: string
}

type IPResponse: void {
  .reply: string
}

interface JavaServiceInterface {
  RequestResponse:
    getIP( IPRequest )( IPResponse ),
    getIP2( IPRequest )( IPResponse )
}