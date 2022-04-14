/*
 Copyright (c) 2016-2022, CKSource Holding sp. z o.o. All rights reserved.
 */

class SetupError extends Error {
	constructor( message ) {
		super( message );

		this.name = this.constructor.name;
		Error.captureStackTrace( this, this.constructor );
	}
}

module.exports = SetupError;
