/*
 Copyright (c) 2016-2020, CKSource - Frederico Knabben. All rights reserved.
 */

import { Construct } from '@aws-cdk/core';
import {
	BlockPublicAccess,
	Bucket,
	BucketEncryption,
	IBucket
} from '@aws-cdk/aws-s3';

export class Storage extends Construct {
	public readonly bucket: IBucket;

	public constructor( scope: Construct, id: string ) {
		super( scope, id );

		this.bucket = new Bucket( this, 'Bucket', {
			encryption: BucketEncryption.KMS,
			publicReadAccess: false,
			blockPublicAccess: BlockPublicAccess.BLOCK_ALL
		} );
	}
}
