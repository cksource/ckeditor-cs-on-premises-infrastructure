const util = require( 'util' );
const exec = util.promisify( require( 'child_process' ).exec );

async function removeContainer( containerName ) {
   await exec( `docker rm -f ${ containerName } || true` );
   console.log( `Docker container ${ containerName } removed` );  
}

const containerNames = [ 
   'quick-start-cs', 
   'quick-start-mysql', 
   'quick-start-redis', 
   'quick-start-node-server' 
];

containerNames.forEach( removeContainer );

