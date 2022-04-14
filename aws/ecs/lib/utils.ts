/*
 Copyright (c) 2016-2022, CKSource Holding sp. z o.o. All rights reserved.
 */

import { Construct } from '@aws-cdk/core';
import { CfnSecret, ISecret, Secret } from '@aws-cdk/aws-secretsmanager';

export class Utils {
	public static isArnLike( value: string ): boolean {
		return value.startsWith( 'arn:' );
	}

	public static createUserProvidedSecret(
		scope: Construct,
		idPrefix: string,
		value: string
	): ISecret {
		let secretArn: string = value;

		if ( !Utils.isArnLike( secretArn ) ) {
			const secret: CfnSecret = new CfnSecret( scope, `${ idPrefix }ValueSecret`, {
				secretString: value
			} );

			secretArn = secret.ref;
		}

		return Secret.fromSecretCompleteArn( scope, `${ idPrefix }Secret`, secretArn );
	}
}
