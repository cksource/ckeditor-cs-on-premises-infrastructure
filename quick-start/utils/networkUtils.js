const axios = require( 'axios' );

exports.findFirstUnusedPort = async ( port ) => {
   const tcpPortUsed = require( 'tcp-port-used' );
   const inUse = await tcpPortUsed.check( port );
   
   if ( inUse ) {
      return this.findFirstUnusedPort( port + 1 );
   }
   return port;
};

exports.getLocalIpAddress = async () => {
   const net = require( 'net' );
   const client = await net.connect( { port: 80, host: "google.com" } );
   
   return new Promise( ( resolve ) => {
      client.on( 'connect', () => {
         client.end();
         resolve( client.localAddress );
      } );
      client.on( 'error', () => {
         client.end();
         resolve( 'localhost' );
      } );
   } );
};

exports.serverIsUp = async ( serverName, context ) => {
   
   let serverUrl = '';

   switch( serverName ) {
      case 'cs':
         serverUrl = `http://localhost:${ context.csPort }/health`;
         break;
      case 'node':
         serverUrl = `http://localhost:${ context.nodePort }/health`;
         break;
   }

   return await healthCheck( serverUrl );

};

async function healthCheck( serverUrl ) {
   
   try {
      await axios.get( serverUrl );
      return true;
   } catch ( err ) {
      return false;
   }
}