const util = require( 'util' );
const exec = util.promisify( require( 'child_process' ).exec );

async function removeContainer( containerName ) {
   
   try {
      await exec( `docker stop ${ containerName }` )
      await exec( `docker container rm ${ containerName }` )
      console.log( `${ containerName } container removed` )
   }
   catch ( err ) {
      console.log( `There was an error during ${ containerName } removal` )
      process.exit(1)
   }
   
}

removeContainer('quick-start-cs')
removeContainer('quick-start-mysql')
removeContainer('quick-start-redis')
removeContainer('quick-start-node-server')
