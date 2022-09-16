/*
 Copyright (c) 2016-2022, CKSource Holding sp. z o.o. All rights reserved.
 */

const axios = require( 'axios' );

exports.wait = waitTime => {
	return new Promise( resolve => setTimeout( resolve, waitTime ) );
};

// eslint-disable-next-line require-await
exports.serverIsUp = async ( serverName, context ) => {
	let serverUrl = '';

	switch ( serverName ) {
		case 'cs':
			serverUrl = `http://localhost:${ context.csPort }/health`;
			break;
		case 'node':
			serverUrl = `http://localhost:${ context.nodePort }/health`;
			break;
	}

	return healthCheck( serverUrl );
};

async function healthCheck( serverUrl ) {
	try {
		await axios.get( serverUrl );

		return true;
	} catch ( err ) {
		return false;
	}
}
