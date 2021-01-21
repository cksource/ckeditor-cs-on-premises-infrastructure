/*
 Copyright (c) 2016-2020, CKSource - Frederico Knabben. All rights reserved.
 */

import { Construct, RemovalPolicy } from '@aws-cdk/core';
import {
	BlockPublicAccess,
	Bucket,
	BucketEncryption,
	IBucket
} from '@aws-cdk/aws-s3';
import { AnyPrincipal, Effect, PolicyStatement } from '@aws-cdk/aws-iam';

import { Network } from './network';

interface IStorageProps {
	network: Network;
}

export class Storage extends Construct {
	public readonly bucket: IBucket;

	private readonly bucketPolicy: PolicyStatement

	public constructor( scope: Construct, id: string, props: IStorageProps ) {
		super( scope, id );

		this.bucket = new Bucket( this, 'Bucket', {
			encryption: BucketEncryption.KMS,
			publicReadAccess: false,
			blockPublicAccess: BlockPublicAccess.BLOCK_ALL,
			removalPolicy: RemovalPolicy.DESTROY
		} );

		this.bucketPolicy = new PolicyStatement( {
			effect: Effect.DENY,
			principals: [ new AnyPrincipal() ],
			resources: [ this.bucket.bucketArn, `${ this.bucket.bucketArn }/*` ],
			actions: [ '*' ]
		} );

		this.bucketPolicy.addCondition( 'StringNotEquals',
			{ 'aws:sourceVpce': props.network.s3Endpoint.vpcEndpointId } );
	}
}
