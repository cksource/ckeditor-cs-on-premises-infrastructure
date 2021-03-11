const util = require( 'util' );
const exec = util.promisify( require( 'child_process' ).exec );
const chalk = require( 'chalk' );
const logger = require('./utils/logger')

const { findFirstUnusedPort, getLocalIpAddress } = require('./utils/networkUtils')
const step = require('./utils/steps.json')
const error = require('./utils/errors.json')
const SetupError = require('./utils/SetupError')

let LICENSE_KEY = '';
let DOCKER_TOKEN = '';
let ENV_SECRET = '';
let IS_DEV = false;
let DOCKER_ENDPOINT = '';
let CS_PORT = 8000;
let NODE_PORT = 3000;
let IP_ADDR = '';
let STEP = '';

(async () => {
   
   try {
      printWelcomeMessage()

      await getCredentials()
   
      validateCredentails()
   
      await validateEnvironment()
   
      await loginToDockerRegistry()
   
      await pullDockerImage()
   
      editDockerComposeFile()
   
      await startDockerContainers()
   
      await createEnvironment()
   
      printInstructionsAfterInstallation()

   } catch ( err ) {
      logger.stepError( STEP )
      
      if ( err instanceof SetupError ) {
         logger.error( err.message )
      } else {
         console.log( err )
      }
      
      process.exit( 1 )
   }

})() ;

function printWelcomeMessage() {
   console.clear();
   logger.info( `   This is ${ chalk.green('On-Premises Quick-Start') } installation` );
   logger.info( `   Add more informations here\n` );
}

async function getCredentials() {
   const argv = require( 'minimist' )( process.argv.slice( 2 ) );
   const prompt = require( 'prompt' );

   LICENSE_KEY = argv.license_key;
   DOCKER_TOKEN = argv.docker_token;
   ENV_SECRET = argv.env_secret;
   IS_DEV = argv.dev;
   DOCKER_ENDPOINT = IS_DEV ? 'docker.cke-cs-dev.com' : 'docker.cke-cs.com';
   CS_PORT = argv.cs_port || await findFirstUnusedPort( CS_PORT );
   NODE_PORT = argv.node_port || await findFirstUnusedPort( NODE_PORT );
   IP_ADDR = await getLocalIpAddress();

   const properties = [];
   if ( !argv.license_key ) properties.push( 'license_key' );
   if ( !argv.docker_token ) properties.push( 'docker_token' );
   if ( !argv.env_secret ) properties.push( 'env_secret' );

   if ( properties.length > 0 ) {
      logger.info( 'Some credentials are missing or were passed incorrectly. Please provide them below. \n' );
   }
   prompt.start();
   const result = await prompt.get( properties );
   
   LICENSE_KEY = LICENSE_KEY || result.license_key;
   DOCKER_TOKEN = DOCKER_TOKEN || result.docker_token;
   ENV_SECRET = ENV_SECRET || result.env_secret;

   if ( properties.length > 0 ) {
      logger.info( '\n' );
   }
}

function validateCredentails() {
   STEP = step.validateCredentials;
   const licenseKeyRegex = /^[0-9a-f]*$/;
   const dockerTokenRegex = /^[0-9a-f\-]{36}$/;

   if ( LICENSE_KEY.length < 300 || !licenseKeyRegex.test( LICENSE_KEY ) ) {
      throw new SetupError( error.invalidLicense )
   }

   if ( !dockerTokenRegex.test( DOCKER_TOKEN ) ) {
      throw new SetupError( error.invalidToken )
   }

   if ( ENV_SECRET.length === 0 ) {
      throw new SetupError( error.invalidSecret )
   }

   logger.stepInfo( STEP );
}

async function validateEnvironment() {
   STEP = step.validateEnvironment;
   try {
      const dockerExec = await exec( 'docker -v' )
      const dockerVersion = parseFloat(dockerExec.stdout.split( ' ' )[2])
      
      if ( dockerVersion === NaN || dockerVersion < 18 ) {
         throw new SetupError( error.dockerVersion )
      } 
   } catch ( err ) {
      throw new SetupError( error.dockerNotInstalled )
   }

   logger.stepInfo( STEP )
}

async function loginToDockerRegistry() {
   STEP = step.dockerAuth; 
   const loginSpinner =  logger.Spinner( STEP );
   loginSpinner.start();

   try {
      await exec( `echo ${DOCKER_TOKEN} | docker login -u cs --password-stdin https://${ DOCKER_ENDPOINT }` )
   } catch( err ) {
      loginSpinner.stop();
      
      if ( err.stderr.includes( "403 Forbidden" )) {
         throw new SetupError( error.wrongToken )
      }
      throw new Error( err.stderr );
   }

   loginSpinner.stop();
   logger.stepInfo( STEP );
}

async function pullDockerImage() {
   STEP = step.dockerPull;
   const downloadSpinner = logger.Spinner( STEP );
   downloadSpinner.start();

   try {
      await exec( `docker pull ${ DOCKER_ENDPOINT }/cs:latest` )
   } catch( err ) {
      downloadSpinner.stop();
      throw new Error( err.stderr );
   }

   downloadSpinner.stop();
   logger.stepInfo( STEP );
}

function editDockerComposeFile() {
   const fs = require( 'fs' );
   const yaml = require( 'js-yaml' );
   
   STEP = step.editFile;
   
   try {
      let dockerComposeFile = fs.readFileSync( './docker-compose.yml', 'utf8' );
      let dockerComposeObject = yaml.load( dockerComposeFile );

      dockerComposeObject.services[ 'ckeditor-cs' ].environment.LICENSE_KEY = LICENSE_KEY;
      dockerComposeObject.services[ 'ckeditor-cs' ].environment.ENVIRONMENTS_MANAGEMENT_SECRET_KEY = ENV_SECRET;
      dockerComposeObject.services[ 'ckeditor-cs' ].ports[ 0 ] = `${ CS_PORT }:8000`;
      dockerComposeObject.services[ 'node-server' ].ports[ 0 ] = `${ NODE_PORT }:3000`;
       
      dockerComposeFile = yaml.dump( dockerComposeObject );
      fs.writeFileSync( './docker-compose.yml', dockerComposeFile, 'utf8' );
   } catch ( err ) {
      throw new Error( err );
   }
   logger.stepInfo( STEP );
}

async function startDockerContainers() {
   // TODO: Add timeout
   // TODO: Output errors from quick-start-cs to log.txt file
   
   STEP = step.dockerUp;
   const dockerSpinner = logger.Spinner( STEP );
   dockerSpinner.start();

   const spawn = require( 'child_process' ).spawn;
   const dockerImages = spawn( "docker-compose", [ "up", "--build" ]);
   
   dockerImages.output = '';
   dockerImages.stdout.on( 'data', ( data ) => {
      dockerImages.output += data.toString();
   });

   return new Promise( ( resolve, reject ) => {
      const serversAvailabilityCheck = setInterval( () => {
         if ( dockerImages.output.includes( 'Server is listening on port 8000.' ) &&
               dockerImages.output.includes( 'Node-server is listening on port 3000' ) ) {
            clearInterval( serversAvailabilityCheck );
            dockerSpinner.stop();
            logger.stepInfo( STEP );
            resolve();
         }

         if ( dockerImages.output.includes( 'Wrong license key.' ) ) {
            dockerSpinner.stop();
            throw new SetupError( error.wrongLicense );
         }
      }, 100); 
   })
}

async function createEnvironment() {
   const axios = require( 'axios' );

   STEP = step.createEnvironment;
   const envSpinner = logger.Spinner( STEP );
   envSpinner.start();

   const body = {
      ip: IP_ADDR,
      csPort: CS_PORT,
      nodePort: NODE_PORT,
      secret: ENV_SECRET
   };

   try {
      await axios.post( `http://localhost:${ NODE_PORT }/init`, body )
   }
   catch ( err ) {
      envSpinner.stop();
      throw new Error( err )
   }
   envSpinner.stop();
   logger.stepInfo( STEP );
}

function printInstructionsAfterInstallation() {
   logger.info( `${ chalk.green('\n   Installation complete') }` );
   logger.info( `   Visit ${ chalk.underline.cyan(`http://${ IP_ADDR }:${ NODE_PORT }`) } to start collaborating` );
}



