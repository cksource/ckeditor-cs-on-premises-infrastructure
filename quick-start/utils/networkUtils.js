const axios = require( 'axios' );

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