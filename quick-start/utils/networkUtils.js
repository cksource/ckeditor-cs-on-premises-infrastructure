exports.findFirstUnusedPort = async ( port ) => {
   const tcpPortUsed = require( 'tcp-port-used' );
   const inUse = await tcpPortUsed.check( port )
   
   if ( inUse ) {
      return this.findFirstUnusedPort( port + 1 )
   }
   return port
}

exports.getLocalIpAddress = async () => {
   const net = require('net');
   const client = await net.connect( { port: 80, host: "google.com" });
   
   return new Promise( ( resolve, reject ) => {
      client.on( 'connect', () => {
         client.end()
         resolve( client.localAddress );
      } );
   })
}