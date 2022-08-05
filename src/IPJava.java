package Jhonny;

import jolie.runtime.JavaService;
import jolie.runtime.Value;
import java.net.InetAddress;
import java.net.DatagramSocket;


public class IPJava extends JavaService
{
    public Value getIP( Value request ) {// throws Exception {
        try{
        String message = request.getFirstChild( "message" ).strValue();
        System.out.println( message );
        InetAddress inetAddress = InetAddress.getLocalHost();
        String a = inetAddress.getHostAddress();
        Value response = Value.create();
        response.getFirstChild( "reply" ).setValue( a );
        return response;
    } catch(Exception e){
        return null;            
    }
}


    public Value getIP2( Value request ) {// throws Exception {
        System.out.println("VADO!" );
        try(final DatagramSocket socket = new DatagramSocket()){
            socket.connect(InetAddress.getByName("8.8.8.8"), 10002);
            String ip = socket.getLocalAddress().getHostAddress();
            Value response = Value.create();
            response.getFirstChild( "reply" ).setValue( ip );
            return response;
          } catch (Exception e) {
            System.out.println( e );
          }
          return null;
        }
}