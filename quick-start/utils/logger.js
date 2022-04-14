/*
 Copyright (c) 2016-2022, CKSource Holding sp. z o.o. All rights reserved.
 */

const platform = require( 'os' ).platform();
const chalk = require( 'chalk' );
const ora = require( 'ora' );

const successIcon = platform === 'win32' ? 'OK ' : '\u2713 ';
const errorIcon = platform === 'win32' ? ' X ' : '\u2718 ';

function info( message ) {
	console.log( chalk.bold( message ) );
}

function stepInfo( message ) {
	console.log( chalk.bold.green( successIcon ) + chalk.bold( message ) );
}

function error( message ) {
	console.log( chalk.bold.red( message + '\n' ) );
}

function stepError( message ) {
	console.log( chalk.bold.red( errorIcon + message + '\n' ) );
}

function warning( message, options = { newLine: true } ) {
	message += options.newLine ? '\n' : '';
	process.stdout.write( chalk.bold.yellow( message ) );
}

function spinner( message ) {
	return ora( chalk.bold( message + '...' ) );
}

module.exports = {
	info,
	stepInfo,
	error,
	stepError,
	warning,
	spinner
};
