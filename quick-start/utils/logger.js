const chalk = require( 'chalk' );
const ora = require( 'ora' );

function info ( message ) {
   console.log( chalk.bold( message ) );
}

function stepInfo ( message ) {
   console.log( chalk.bold.green( '\u2713 ' ) + chalk.bold( message ) );
}

function error ( message ) {
   console.log( chalk.bold.red( message + '\n' ) );
}

function stepError ( message ) {
   console.log( chalk.bold.red( '\u2718 '  + message + '\n' ) );
}

function Spinner ( message ) {
   return ora( chalk.bold( message + "..." ) );
}

module.exports = { 
   info,
   stepInfo,
   error,
   stepError,
   Spinner
}