let LICENSE_KEY = '';
let DOCKER_TOKEN = '';
let ENV_SECRET = '';
let CS_PORT = 8005;
let NODE_PORT = 3000;
let IP_ADDR = '';

(async function onPremisesSetup() {

   getCredentials()

   await pullDockerImage()

   editDockerComposeFile()

   await startDockerContainers()

   await createEnvironment()

   console.log( `Visit http://${ IP_ADDR }:${ NODE_PORT } to start collaborating` )

})();


function getCredentials() {

const argv = require( 'minimist' )( process.argv.slice( 2 ) );

LICENSE_KEY = argv.license_key;
DOCKER_TOKEN = argv.docker_token;
ENV_SECRET = argv.env_secret;

}

async function pullDockerImage() {
   const util = require('util');
   const exec = util.promisify(require('child_process').exec);

   try {
      //TODO: change endpoints to production before publishing
      console.log( 'Logining to docker image registry...' )
      await exec( `docker login -u cs -p ${ DOCKER_TOKEN } https://docker.cke-cs-dev.com` )
      console.log( 'Login to docker image registry successful' )

      console.log( 'Downloading docker image...' )
      await exec( `docker pull docker.cke-cs-dev.com/cs:latest` )
      console.log( 'Docker image download complete' )

   } catch( err ) {
      //TODO: print clear instructions for users when token is incorrect
      console.log( err.stderr )
   }
}

function editDockerComposeFile() {

   const fs = require('fs');
   const yaml = require('js-yaml');
   
   try {
      // read file 
      console.log('Editing docker-compose.yml file...')
      let dockerComposeFile = fs.readFileSync('./docker-compose.yml', 'utf8');
      let dockerComposeObject = yaml.load(dockerComposeFile);

      // edit file 
      dockerComposeObject.services['ckeditor-cs'].environment.LICENSE_KEY = LICENSE_KEY;
      dockerComposeObject.services['ckeditor-cs'].ports[0] = `${ CS_PORT }:8000`;
      dockerComposeObject.services['node-server'].ports[0] = `${ NODE_PORT }:3000`;
       
      // save file
      dockerComposeFile = yaml.dump(dockerComposeObject);
      fs.writeFileSync('./docker-compose.yml', dockerComposeFile, 'utf8');
      console.log('docker-compose.yml file edit done')

   } catch ( err ) {
       console.log( err );
   }
}

async function startDockerContainers() {
   console.log( 'Starting docker containers...' );

   try {
      const spawn = require( 'child_process' ).spawn;
      const dockerImages = spawn( "docker-compose", [ "up", "--build" ]);
      
      dockerImages.output = '';
      dockerImages.stdout.on( 'data', function( data ) {
         dockerImages.output += data.toString();
      });

      return new Promise( ( resolve, reject ) => {
         var serversAvailabilityCheck = setInterval( () => {

            if ( dockerImages.output.includes( 'Server is listening on port 8000.' ) &&
                 dockerImages.output.includes( 'Node-server is listening on port 3000' ) ) {
               console.log( 'Docker containers are running' );
               clearInterval( serversAvailabilityCheck );
               resolve();
            }
         }, 100); 
      })
   }
   catch (err) {
      console.log(err)
   }
}

async function createEnvironment() {

   const axios = require('axios');
   const os = require('os');

   // get machine ip address
   // send post request to node-server
   // wait for 'Done' signal from node-server
   const interfaces = os.networkInterfaces();
   const machineIpAddresses = []

   Object.keys( interfaces ).forEach( device => {
      interfaces[ device ].forEach( details => {
        if ( details.family === 'IPv4' ) {
         machineIpAddresses.push( details.address );
        }
      } )
   } )

   const networkIpAddresses = machineIpAddresses.filter(ip => ip !== '127.0.0.1')
   if ( networkIpAddresses.length > 0 ) {
      IP_ADDR = networkIpAddresses[0];
   } else {
      IP_ADDR = '127.0.0.1'
   }

   const body = {
      ip: IP_ADDR,
      csPort: CS_PORT,
      nodePort: NODE_PORT,
      secret: ENV_SECRET
   }

   try {
      await axios.post( `http://localhost:${ NODE_PORT }/init`, body )
   }
   catch ( err ) {
      console.log( err.message )
   }
}


