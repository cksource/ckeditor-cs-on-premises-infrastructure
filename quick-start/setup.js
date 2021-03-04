let LICENSE_KEY = '';
let DOCKER_TOKEN = '';
let ENV_SECRET = '';

(async function onPremisesSetup() {

   getCredentials()

})();


function getCredentials() {

const argv = require( 'minimist' )( process.argv.slice( 2 ) );

LICENSE_KEY = argv.license_key;
DOCKER_TOKEN = argv.docker_token;
ENV_SECRET = argv.env_secret;

}