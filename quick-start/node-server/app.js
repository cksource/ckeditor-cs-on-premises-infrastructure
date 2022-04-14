/*
 Copyright (c) 2016-2022, CKSource Holding sp. z o.o. All rights reserved.
 */

const crypto = require( 'crypto' );
const express = require( 'express' );
const cors = require( 'cors' );
const jwt = require( 'jsonwebtoken' );
const axios = require( 'axios' );

let environmentID = '';
let accessKey = '';
let envSecret = '';

const app = express();
app.use( express.json( { limit: '10mb' } ) );
app.use( cors() );

// Serving editor sample from node.js server
app.use( express.static( 'editor' ) );
app.get( '/', ( req, res ) => {
	res.redirect( '/sample/index.html' );
} );

// Token endpoint
app.get( '/token', generateToken );

// Create environment
app.post( '/init', createEnvironment );

// Health check
app.get( '/health', getHealthStatus );

app.listen( 3000, () => console.log( 'Node-server is listening on port 3000' ) );

function generateToken( req, res ) {
	const payload = {
		aud: environmentID,
		sub: req.query[ 'user.id' ] || 'user-1',
		user: {
			name: req.query[ 'user.name' ] || 'John Doe',
			avatar: req.query[ 'user.avatar' ] || ''
		},
		auth: {
			'collaboration': {
				'*': {
					'role': req.query.role || 'writer'
				}
			}
		}
	};

	const token = jwt.sign( payload, accessKey, { algorithm: 'HS256' } );
	res.send( token );
}

async function createEnvironment( req, res ) {
	envSecret = req.body.secret;

	const newEnvironment = {
		id: _randomString( 20 ),
		name: 'On-Premises Quick-start',
		organizationId: _randomString( 20 ),
		accessKeys: [ { name: 'Access Key', value: _randomString( 20 ) } ],
		apiSecret: _randomString( 20 ),
		services: [
			{
				id: _randomString( 24 ),
				type: 'easy-image'
			},
			{
				id: _randomString( 24 ),
				type: 'collaboration'
			}
		]
	};
	const timestamp = Date.now();
	const uri = 'http://ckeditor-cs:8000/environments';
	const signature = _generateSignature( envSecret, 'POST', uri, timestamp, newEnvironment );
	const headers = {
		'X-CS-Signature': signature,
		'X-CS-Timestamp': timestamp
	};

	try {
		await axios.post( uri, newEnvironment, { headers } );
		console.log( 'New Environment created.' );
		environmentID = newEnvironment.id;
		accessKey = newEnvironment.accessKeys[ 0 ].value;

		res.send( 'Done' );
	} catch ( err ) {
		console.log( err );
		res.status( 500 ).send( 'Could not create environment. ' + err.message );
	}
}

function getHealthStatus( req, res ) {
	res.send( {
		uptime: process.uptime(),
		timestamp: Date.now()
	} );
}

function _generateSignature( apiSecret, method, uri, timestamp, body ) {
	const url = new URL( uri );
	const path = url.pathname + url.search;

	const hmac = crypto.createHmac( 'SHA256', apiSecret );

	hmac.update( `${ method.toUpperCase() }${ path }${ timestamp }` );

	if ( body ) {
		hmac.update( Buffer.from( JSON.stringify( body ) ) );
	}

	return hmac.digest( 'hex' );
}

function _randomString( length ) {
	return crypto.randomBytes( length / 2 ).toString( 'hex' );
}
