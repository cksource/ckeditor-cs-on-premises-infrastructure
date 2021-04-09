const util = require( 'util' );
const fs = require( 'fs' );
const exec = util.promisify( require( 'child_process' ).exec );
const execSync = require( 'child_process' ).execSync;
const chalk = require( 'chalk' );

const { findFirstUnusedPort, getLocalIpAddress } = require('./utils/networkUtils');
const logger = require('./utils/logger');
const SetupError = require('./utils/SetupError');
const step = require('./utils/steps.json');
const error = require('./utils/errors.json');

let CURRENT_STEP = '';
let LICENSE_KEY = '';
let DOCKER_TOKEN = '';
let ENV_SECRET = '';
let DOCKER_ENDPOINT = '';
let IP_ADDR = '';
let CS_PORT = 8000;
let NODE_PORT = 3000;
let IS_DEV = false;
let KEEP_CONTAINERS = false;
let CLEANUP_NEEDED = false;

(async () => {
   try {
      printWelcomeMessage();

      await readArguments();
   
      await validateCredentails();
   
      await validateEnvironment();
   
      await loginToDockerRegistry();
   
      await pullDockerImage();

      editDockerComposeFile();
   
      await startDockerContainers();
   
      await createEnvironment();
   
      printInstructionsAfterInstallation();

   } catch ( err ) {
      logger.stepError( CURRENT_STEP );

      if ( err instanceof SetupError ) {    
         logger.error( err.message );
      } else {
         console.log( err );
      }

      process.exit( 1 );
   }
})() ;

function printWelcomeMessage() {
   console.clear();
   logger.info( `   This is ${ chalk.green('On-Premises Quick-Start') } installation` );
   logger.info( `   Add more informations here\n` );
}

async function readArguments() {
   const argv = require( 'minimist' )( process.argv.slice( 2 ) );
   CURRENT_STEP = step.getCredentials;
   
   IS_DEV = argv.dev;
   DOCKER_ENDPOINT = IS_DEV ? 'docker.cke-cs-dev.com' : 'docker.cke-cs.com';
   IP_ADDR = await getLocalIpAddress();
   CS_PORT = argv.cs_port || await findFirstUnusedPort( CS_PORT );
   NODE_PORT = argv.node_port || await findFirstUnusedPort( NODE_PORT );
   KEEP_CONTAINERS = argv.keep_containers;

   if ( !argv.license_key || !argv.docker_token || !argv.env_secret ) {
      logger.warning( error.missingCredentials );
   }

   LICENSE_KEY = argv.license_key ? argv.license_key.trim() : await askForCredential( 'license_key' );
   DOCKER_TOKEN = argv.docker_token ? argv.docker_token.trim() : await askForCredential( 'docker_token' ); 
   ENV_SECRET = argv.env_secret ? argv.env_secret.trim() : await askForCredential( 'env_secret' ); 
}

async function validateCredentails() {
   CURRENT_STEP = step.validateCredentials;
   const licenseKeyRegex = /^[0-9a-f]{300,}$/;
   const dockerTokenRegex = /^[0-9a-f\-]{36}$/;

   if ( !licenseKeyRegex.test( LICENSE_KEY ) ) {
      logger.warning( error.invalidLicense );
      LICENSE_KEY = await askForCredential( 'license_key' );
      return validateCredentails();
   }

   if ( !dockerTokenRegex.test( DOCKER_TOKEN ) ) {
      logger.warning( error.invalidToken );
      DOCKER_TOKEN = await askForCredential( 'docker_token' );
      return validateCredentails();
   }

   if ( ENV_SECRET.length === 0 ) {
      logger.warning( error.invalidSecret );
      ENV_SECRET = await askForCredential( 'env_secret' );
      return validateCredentails();
   }

   logger.stepInfo( CURRENT_STEP );
}

async function validateEnvironment() {
   CURRENT_STEP = step.validateEnvironment;
   let dockerVersion = '';

   try {
      const dockerExec = await exec( 'docker -v' );
      dockerVersion = parseFloat( dockerExec.stdout.split( ' ' )[ 2 ] );
      
      if ( dockerVersion < 18 ) {
         throw dockerVersion
      } 
   } catch ( err ) {
      if (err === dockerVersion) {
         throw new SetupError( error.dockerVersion );
      }
      throw new SetupError( error.dockerNotInstalled );
   }

   logger.stepInfo( CURRENT_STEP );
}

async function loginToDockerRegistry() {
   CURRENT_STEP = step.dockerAuth; 
   const loginSpinner = logger.spinner( CURRENT_STEP );
   loginSpinner.start();

   try {
      await exec( `echo ${DOCKER_TOKEN} | docker login -u cs --password-stdin https://${ DOCKER_ENDPOINT }` );
   } catch( err ) {
      loginSpinner.stop();
      
      if ( err.stderr.includes( "403 Forbidden" ) ) {
         throw new SetupError( error.wrongToken );
      }
      throw new Error( err.stderr );
   }

   loginSpinner.stop();
   logger.stepInfo( CURRENT_STEP );
}

async function pullDockerImage() {
   CURRENT_STEP = step.dockerPull;
   const downloadSpinner = logger.spinner( CURRENT_STEP );
   downloadSpinner.start();

   try {
      await exec( `docker pull ${ DOCKER_ENDPOINT }/cs:latest` );
   } catch( err ) {
      downloadSpinner.stop();
      throw new Error( err.stderr );
   }

   downloadSpinner.stop();
   logger.stepInfo( CURRENT_STEP );
}

function editDockerComposeFile() {
   const yaml = require( 'js-yaml' );
   
   CURRENT_STEP = step.editFile;
   
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
   logger.stepInfo( CURRENT_STEP );
}

async function startDockerContainers() {
   CURRENT_STEP = step.dockerUp;
   CLEANUP_NEEDED  = true;
   const dockerSpinner = logger.spinner( CURRENT_STEP );
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
            clearTimeout( timeout );
            dockerSpinner.stop();
            logger.stepInfo( CURRENT_STEP );
            resolve();
         }
         
         if ( dockerImages.output.includes( 'Wrong license key.' ) ) {
            dockerSpinner.stop();
            reject( new SetupError( error.wrongLicense ) );
         }
      }, 100); 

      const timeout = setTimeout( () => {
         dockerSpinner.stop();
         fs.writeFileSync( './log.txt', dockerImages.output, 'utf-8' );
         reject( new SetupError (error.containersTimeout) );
      }, 10 * 60 * 1000)
   })
}

async function createEnvironment() {
   const axios = require( 'axios' );

   CURRENT_STEP = step.createEnvironment;
   const envSpinner = logger.spinner( CURRENT_STEP );
   envSpinner.start();

   const body = {
      ip: IP_ADDR,
      csPort: CS_PORT,
      nodePort: NODE_PORT,
      secret: ENV_SECRET
   };

   try {
      await axios.post( `http://localhost:${ NODE_PORT }/init`, body );
   }
   catch ( err ) {
      envSpinner.stop();
      throw new Error( err );
   }
   envSpinner.stop();
   logger.stepInfo( CURRENT_STEP );
}

function printInstructionsAfterInstallation() {
   logger.info( `${ chalk.green('\n   Installation complete') }` );
   logger.info( `   Visit ${ chalk.underline.cyan(`http://${ IP_ADDR }:${ NODE_PORT }`) } to start collaborating` );
}

async function askForCredential( credential ) {
   const prompt = require( 'prompt' );
   prompt.start();
   try {
      const input = await prompt.get( [ credential ] );
      return input[ credential ].trim();
   } catch ( err ) {
      logger.info( '\n' );
      throw new SetupError( '' );
   }
}

process.on( 'exit', () => {
   if ( !KEEP_CONTAINERS && CLEANUP_NEEDED ) {
      logger.info( '\nRemoving created containers...' );
      execSync( 'npm run cleanup' );
   }
} );

process.on( 'SIGINT', () => {
   process.exit(2)
} );