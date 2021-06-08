const util = require( 'util' );
const fs = require( 'fs' );
const exec = util.promisify( require( 'child_process' ).exec );
const execSync = require( 'child_process' ).execSync;
const spawn = require( 'child_process' ).spawn;
const chalk = require( 'chalk' );

const { serverIsUp } = require( './utils/networkUtils' );
const logger = require( './utils/logger' );
const SetupError = require( './utils/SetupError' );
const step = require( './utils/steps.json' );
const error = require( './utils/errors.json' );

( async () => {
	const context = {
		currentStep: '',
		licenseKey: '',
		dockerToken: '',
		envSecret: '',
		dockerEndpoint: '',
		ipAddr: '',
		csPort: 8000,
		nodePort: 3000,
		keepContainers: false,
		cleanupNeeded: false
	};

	process.on( 'exit', () => {
		if ( !context.keepContainers && context.cleanupNeeded ) {
			logger.info( '\nRemoving created containers...' );
			execSync( 'npm run cleanup' );
		}
	} );

	process.on( 'SIGINT', () => {
		process.exit( 2 );
	} );

	try {
		printWelcomeMessage();

		await readArguments( context );

		await validateCredentails( context );

		await validateEnvironment( context );

		await loginToDockerRegistry( context );

		await pullDockerImage( context );

		editDockerComposeFile( context );

		await startDockerContainers( context );

		await createEnvironment( context );

		printInstructionsAfterInstallation( context );
	} catch ( err ) {
		logger.stepError( context.currentStep );

		if ( err instanceof SetupError ) {
			logger.error( err.message );
		} else {
			logger.error( err );
		}

		process.exit( 1 );
	}
} )();

function printWelcomeMessage() {
	logger.info( '\n\n' );
	logger.info( `${ chalk.green( 'Collaboration Server On-Premises Quick-Start' ) } installation` );
	logger.info( `This setup script allows you to quickly set up infrastructure needed to use CKEditor 5 with
Real-Time Collaboration and Collaboration Server On-Premises.` );
	logger.warning( `Collaboration Server On-Premises Quick-Start can be only used for testing purposes 
during local development and it cannot be used in production.\n` );
}

async function readArguments( context ) {
	const argv = require( 'minimist' )( process.argv.slice( 2 ) );
	context.currentStep = step.getCredentials;

	context.dockerEndpoint = argv.docker_endpoint || 'docker.cke-cs.com';
	context.ipAddr = 'localhost';
	context.csPort = argv.cs_port || context.csPort;
	context.nodePort = argv.node_port || context.nodePort;
	context.keepContainers = argv.keep_containers;

	if ( !argv.license_key || !argv.docker_token || !argv.env_secret ) {
		logger.warning( error.missingCredentials );
	}

	context.licenseKey = await askForCredentialIfMissing( argv, 'license_key' );
	context.dockerToken = await askForCredentialIfMissing( argv, 'docker_token' );
	context.envSecret = await askForCredentialIfMissing( argv, 'env_secret' );
}

async function validateCredentails( context ) {
	context.currentStep = step.validateCredentials;
	const licenseKeyRegex = /^[0-9a-f]{300,}$/;
	const dockerTokenRegex = /^[0-9a-f-]{36}$/;

	if ( !licenseKeyRegex.test( context.licenseKey ) ) {
		logger.warning( error.invalidLicense );
		context.licenseKey = await askForCredential( 'license_key' );
	}
	else if ( !dockerTokenRegex.test( context.dockerToken ) ) {
		logger.warning( error.invalidToken );
		context.dockerToken = await askForCredential( 'docker_token' );
	}
	else if ( context.envSecret.length === 0 ) {
		logger.warning( error.invalidSecret );
		context.envSecret = await askForCredential( 'env_secret' );
	} else {
		logger.stepInfo( context.currentStep );

		return;
	}

	return validateCredentails( context );
}

async function validateEnvironment( context ) {
	context.currentStep = step.validateEnvironment;
	const dockerVersionRegex = /Version:\s*(1[89]|[2-9]\d|\d{3,}).\d*.\d*/;
	let dockerOutput;

	try {
		dockerOutput = await exec( 'docker version' );
	} catch ( err ) {
		if ( err.message.includes( 'command not found' ) ) {
			throw new SetupError( error.dockerNotInstalled );
		}

		if ( err.message.includes( 'Cannot connect to the Docker daemon' ) ) {
			throw new SetupError( error.dockerNotRunning );
		}

		throw new Error( err );
	}

	if ( !dockerVersionRegex.test( dockerOutput.stdout ) ) {
		throw new SetupError( error.dockerVersion );
	}
	logger.stepInfo( context.currentStep );
}

async function loginToDockerRegistry( context ) {
	context.currentStep = step.dockerAuth;
	const loginSpinner = logger.spinner( context.currentStep );
	loginSpinner.start();

	try {
		await exec( `echo ${ context.dockerToken } | docker login -u cs --password-stdin https://${ context.dockerEndpoint }` );
	} catch ( err ) {
		loginSpinner.stop();

		if ( err.stderr.includes( '403 Forbidden' ) ) {
			throw new SetupError( error.wrongToken );
		}

		throw new Error( err.stderr );
	}

	loginSpinner.stop();
	logger.stepInfo( context.currentStep );
}

async function pullDockerImage( context ) {
	context.currentStep = step.dockerPull;
	const downloadSpinner = logger.spinner( context.currentStep );
	downloadSpinner.start();

	try {
		await exec( `docker pull ${ context.dockerEndpoint }/cs:latest` );
	} catch ( err ) {
		downloadSpinner.stop();
		throw new Error( err.stderr );
	}

	downloadSpinner.stop();
	logger.stepInfo( context.currentStep );
}

function editDockerComposeFile( context ) {
	const yaml = require( 'js-yaml' );

	context.currentStep = step.editFile;

	let dockerComposeFile = fs.readFileSync( './docker-compose-template.yml', 'utf8' );
	const dockerComposeObject = yaml.load( dockerComposeFile );

	dockerComposeObject.services[ 'ckeditor-cs' ].image = `${ context.dockerEndpoint }/cs:latest`;
	dockerComposeObject.services[ 'ckeditor-cs' ].environment.LICENSE_KEY = context.licenseKey;
	dockerComposeObject.services[ 'ckeditor-cs' ].environment.ENVIRONMENTS_MANAGEMENT_SECRET_KEY = context.envSecret;
	dockerComposeObject.services[ 'ckeditor-cs' ].ports[ 0 ] = `${ context.csPort }:8000`;
	dockerComposeObject.services[ 'node-server' ].ports[ 0 ] = `${ context.nodePort }:3000`;

	dockerComposeFile = yaml.dump( dockerComposeObject );
	fs.writeFileSync( './docker-compose.yml', dockerComposeFile, 'utf8' );

	logger.stepInfo( context.currentStep );
}

function startDockerContainers( context ) {
	context.currentStep = step.dockerUp;
	context.cleanupNeeded = true;
	const dockerSpinner = logger.spinner( context.currentStep );
	dockerSpinner.start();

	const dockerComposeUp = spawn( 'docker-compose', [ 'up', '--build' ] );

	dockerComposeUp.output = '';
	dockerComposeUp.stdout.on( 'data', data => {
		dockerComposeUp.output += data.toString();
	} );

	return new Promise( ( resolve, reject ) => {
		const timeout = setTimeout( () => {
			dockerSpinner.stop();
			fs.writeFileSync( './log.txt', dockerComposeUp.output, 'utf-8' );
			reject( new SetupError( error.containersTimeout ) );
		}, 15 * 60 * 1000 );

		const serversAvailabilityCheck = setInterval( async () => {
			if ( await serverIsUp( 'cs', context ) && await serverIsUp( 'node', context ) ) {
				clearInterval( serversAvailabilityCheck );
				clearTimeout( timeout );
				dockerSpinner.stop();
				logger.stepInfo( context.currentStep );
				resolve();
			}

			if ( dockerComposeUp.output.includes( 'Wrong license key.' ) ) {
				dockerSpinner.stop();
				reject( new SetupError( error.wrongLicense ) );
			}
		}, 200 );
	} );
}

async function createEnvironment( context ) {
	const axios = require( 'axios' );

	context.currentStep = step.createEnvironment;
	const envSpinner = logger.spinner( context.currentStep );
	envSpinner.start();

	const body = {
		ip: context.ipAddr,
		csPort: context.csPort,
		nodePort: context.nodePort,
		secret: context.envSecret
	};

	try {
		await axios.post( `http://localhost:${ context.nodePort }/init`, body );
	}
	catch ( err ) {
		envSpinner.stop();
		throw err;
	}
	envSpinner.stop();
	logger.stepInfo( context.currentStep );
}

function printInstructionsAfterInstallation( context ) {
	logger.info( `${ chalk.green( '\nInstallation complete' ) }` );
	logger.info( `Visit ${ chalk.underline.cyan( `http://${ context.ipAddr }:${ context.nodePort }` ) } to start collaborating` );
}

async function askForCredential( credential ) {
	const prompt = require( 'prompt' );

	let credentialDescription = '';
	switch ( credential ) {
		case 'license_key':
			credentialDescription = error.licenseKeyDescription;
			break;
		case 'docker_token':
			credentialDescription = error.dockerTokenDescription;
			break;
		case 'env_secret':
			credentialDescription = error.envSecretDescription;
			break;
	}

	logger.info( credentialDescription );
	prompt.start();

	try {
		const input = await prompt.get( [ credential ] );

		return input[ credential ].trim();
	} catch ( err ) {
		logger.info( '\n' );
		throw new SetupError( '' );
	}
}

// eslint-disable-next-line require-await
async function askForCredentialIfMissing( argv, credential ) {
	return argv[ credential ] ? argv[ credential ].trim() : askForCredential( credential );
}
