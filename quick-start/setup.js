const util = require('util');
const exec = util.promisify(require('child_process').exec);

let LICENSE_KEY = '';
let DOCKER_TOKEN = '';
let ENV_SECRET = '';

(async function onPremisesSetup() {

   getCredentials()

   await pullDockerImage()

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