const util = require('util');
const exec = util.promisify(require('child_process').exec);

let LICENSE_KEY = '';
let DOCKER_TOKEN = '';
let ENV_SECRET = '';
let CS_PORT = 8005;
let NODE_PORT = 300;

(async function onPremisesSetup() {

   getCredentials()

   await pullDockerImage()

   editDockerComposeFile()

})();


function getCredentials() {

const argv = require( 'minimist' )( process.argv.slice( 2 ) );

LICENSE_KEY = argv.license_key;
DOCKER_TOKEN = argv.docker_token;
ENV_SECRET = argv.env_secret;

}

async function pullDockerImage() {
   try {
      //TODO: change endpoints to production before publishing
      console.log( 'Logining to docker image registry...' )
      await exec( `docker login -u cs -p ${ DOCKER_TOKEN } https://docker.cke-cs-dev.com` )
      console.log( 'Login to docker image registry sucessful' )

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
       
      // save file
      dockerComposeFile = yaml.dump(dockerComposeObject);
      fs.writeFileSync('./docker-compose.yml', dockerComposeFile, 'utf8');
      console.log('docker-compose.yml file edit done')

   } catch ( err ) {
       console.log( err );
   }
}