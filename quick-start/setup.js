const util = require( 'util' );
const exec = util.promisify( require( 'child_process' ).exec );
const chalk = require( 'chalk' );
const ora = require( 'ora' );

let LICENSE_KEY = '';
let DOCKER_TOKEN = '';
let ENV_SECRET = '';
let CS_PORT = 8005;
let NODE_PORT = 3000;
let IP_ADDR = '';

(async function onPremisesSetup() {
   printWelcomeMessage()

   await getCredentials()

   validateCredentails()

   await loginToDockerRegistry()

   await pullDockerImage()

   editDockerComposeFile()

   await startDockerContainers()

   await createEnvironment()

   printInstructionsAfterInstallation()

} )();


function printWelcomeMessage() {
   console.clear()
   info( `   This is ${ chalk.green('On-Premises Quick-Start') } installation` )
   info( `   Add more informations here\n` )
}

async function getCredentials() {
   const argv = require( 'minimist' )( process.argv.slice( 2 ) );
   const prompt = require( 'prompt' );

   LICENSE_KEY = argv.license_key;
   DOCKER_TOKEN = argv.docker_token;
   ENV_SECRET = argv.env_secret;
   IS_DEV = argv.dev;

   const properties = [];
   if ( !argv.license_key ) properties.push( 'license_key' );
   if ( !argv.docker_token ) properties.push( 'docker_token' );
   if ( !argv.env_secret ) properties.push( 'env_secret' );

   if ( properties.length > 0 ) {
      info( 'Some credentials are missing or were passed incorrectly. Please provide them below. \n' )
   }
   prompt.start();
   result = await prompt.get( properties );
   
   LICENSE_KEY = LICENSE_KEY || result.license_key;
   DOCKER_TOKEN = DOCKER_TOKEN || result.docker_token;
   ENV_SECRET = ENV_SECRET || result.env_secret;

   if ( properties.length > 0 ) {
      info( '\n' )
   }
}

function validateCredentails() {
   const licenseKeyRegex = /^[0-9a-f]*$/
   if ( LICENSE_KEY.length < 300 || !licenseKeyRegex.test( LICENSE_KEY ) ) {
      stepError( 'Validating credentials' )
      info( chalk.red( '\n Provided License Key is invalid \n' ) )
      process.exit(1)
   }

   const dockerTokenRegex = /^[0-9a-f\-]*$/
   if ( DOCKER_TOKEN.length != 36 || !dockerTokenRegex.test( DOCKER_TOKEN ) ) {
      stepError( 'Validating credentials' )
      info( chalk.red( '\n Provided Docker Token is invalid \n' ) )
      process.exit(1)
   }

   if ( ENV_SECRET.length = 0 ) {
      stepError( 'Validating credentials' )
      info( chalk.red( '\n Environment secret can not be empty \n' ) )
      process.exit(1)
   }

   stepInfo( 'Validating credentials' )
}

async function loginToDockerRegistry() {
   const loginSpinner = new Spinner( 'Docker registry authorization...' );
   loginSpinner.start();

   try {
      //TODO: change endpoints to production before publishing
      await exec( `docker login -u cs -p ${ DOCKER_TOKEN } https://docker.cke-cs-dev.com` )

      loginSpinner.stop();
      stepInfo( 'Docker registry authorization' )
   } catch( err ) {
      //TODO: print clear instructions for users when token is incorrect
      loginSpinner.stop();
      stepError( 'Docker registry authorization\n' )
      console.log(err.stderr)
      process.exit(1)
   }
}

async function pullDockerImage() {
   const downloadSpinner = new Spinner( 'Pulling docker image...' );
   downloadSpinner.start();

   try {
      //TODO: change endpoints to production before publishing
      await exec( `docker pull docker.cke-cs-dev.com/cs:latest` )

      downloadSpinner.stop();
      stepInfo( 'Pulling docker image' )
   } catch( err ) {
      //TODO: print clear instructions for users: Check your internet connection and try again?
      downloadSpinner.stop();
      stepError( 'Pulling docker image\n' )
      console.log(err.stderr)
      process.exit(1)
   }
}

function editDockerComposeFile() {
   const fs = require( 'fs' );
   const yaml = require( 'js-yaml' );
   
   try {
      let dockerComposeFile = fs.readFileSync( './docker-compose.yml', 'utf8' );
      let dockerComposeObject = yaml.load( dockerComposeFile );

      dockerComposeObject.services[ 'ckeditor-cs' ].environment.LICENSE_KEY = LICENSE_KEY;
      dockerComposeObject.services[ 'ckeditor-cs' ].ports[ 0 ] = `${ CS_PORT }:8000`;
      dockerComposeObject.services[ 'node-server' ].ports[ 0 ] = `${ NODE_PORT }:3000`;
       
      dockerComposeFile = yaml.dump( dockerComposeObject );
      fs.writeFileSync( './docker-compose.yml', dockerComposeFile, 'utf8' );
      stepInfo( 'Editing docker-compose.yml file' )
   } catch ( err ) {
      stepError( 'Editing docker-compose.yml file\n' )
      console.log(err.message)
      process.exit(1)
   }
}

async function startDockerContainers() {
   const dockerSpinner = new Spinner( 'Starting docker containers...' );
   dockerSpinner.start();

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
            clearInterval( serversAvailabilityCheck );
            dockerSpinner.stop();
            stepInfo( 'Starting docker containers' )
            resolve();
         }

         if ( dockerImages.output.includes( 'Wrong license key.' ) ) {
            dockerSpinner.stop();
            stepError( 'Starting docker containers' );
            process.exit(1)
         }
      }, 100); 
   })
}

async function createEnvironment() {
   const axios = require('axios');
   const interfaces = require('os').networkInterfaces();
   const machineIpAddresses = []

   const envSpinner = new Spinner( 'Creating environment...' );
   envSpinner.start();

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
      envSpinner.stop();
      stepInfo( 'Creating environment' )
   }
   catch ( err ) {
      envSpinner.stop();
      stepError( 'Creating environment' )
   }
}

function printInstructionsAfterInstallation() {
   info( `${ chalk.green('\n   Installation complete') }` )
   info( `   Visit ${ chalk.underline.cyan(`http://${ IP_ADDR }:${ NODE_PORT }`) } to start collaborating` )
}

function stepError( message ) {
   console.log( chalk.bold.red( '\u2718 '  + message ) )
}

function stepInfo( message ) {
   console.log( chalk.bold.green( '\u2713 ' ) + chalk.bold( message ) )
}

function Spinner( message ) {
   return ora( chalk.bold( message ) )
}

function info( message ) {
   console.log( chalk.bold( message ) )
}
