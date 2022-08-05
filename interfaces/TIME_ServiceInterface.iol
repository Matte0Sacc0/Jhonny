  
interface TIME_ServiceInterface {
  OneWay: setTimeZone
  RequestResponse:
    getTimeStamp, //throws Error? e manda string a monitor?
    getTimeString
}