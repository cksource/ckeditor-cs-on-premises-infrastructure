/*
 Copyright (c) 2016-2020, CKSource - Frederico Knabben. All rights reserved.
 */

import { Annotations, Construct } from '@aws-cdk/core';

const REQUIRED_CONFIG_KEYS: string[] = [ 'LICENSE_KEY', 'ENVIRONMENTS_MANAGEMENT_SECRET_KEY' ];
const ENV_CONFIG_DEFAULTS: [string, string][] = [
	[ 'APPLICATION_HTTP_PORT', '80' ]
];

export class CsEnvironmentConfig extends Construct {
	private readonly store: Map<string, string> = new Map( ENV_CONFIG_DEFAULTS );

	public constructor( scope: Construct, config: string[] ) {
		super( scope, 'CsEnvironmentConfig' );

		config.forEach( cfnValue => {
			const [ key, value ] = cfnValue.split( '=' );

			this.store.set( key.trim().toUpperCase(), value );
		} );

		REQUIRED_CONFIG_KEYS.forEach( key => {
			if ( !this.store.has( key ) ) {
				Annotations.of( this ).addError( `Environment config parameter "${ key }" is required.` );
			}
		} );
	}

	public get( key: string ): string {
		if ( !this.store.has( key ) ) {
			Annotations.of( this ).addError( `Environment config parameter "${ key }" not found.` );
		}

		return this.store.get( key ) ?? '';
	}

	public toObject(): {[k: string]: string;} {
		const result: {[k: string]: string;} = {};

		for ( const [ key, value ] of this.store.entries() ) {
			result[ key ] = value;
		}

		return result;
	}
}
