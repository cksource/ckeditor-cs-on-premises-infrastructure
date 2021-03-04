const util = require('util');
const exec = util.promisify(require('child_process').exec);

async function removeContainer( containerName ) {
   try {
      //const { stdout: out1, stderr: err1 } =
      await exec( `docker stop ${ containerName }` )
      
      //const { stdout: out2, stderr: err2 } =  
      await exec( `docker container rm ${ containerName }` )
      
      console.log( `${ containerName } container removed` )
   }
   catch(err) {
      console.log(`There was an error while removing ${ containerName }`)
      return
   }
   
}

removeContainer('quick-start-cs')
removeContainer('quick-start-mysql')
removeContainer('quick-start-redis')
removeContainer('quick-start-node-server')
