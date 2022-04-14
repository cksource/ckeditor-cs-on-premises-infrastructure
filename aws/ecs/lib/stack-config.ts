/*
 Copyright (c) 2016-2022, CKSource Holding sp. z o.o. All rights reserved.
 */

import { LaunchType } from '@aws-cdk/aws-ecs';
import { Annotations, Construct } from '@aws-cdk/core';

export class StackConfig extends Construct {
	public readonly dockerRegistryAuthToken: string;

	public readonly version: string;

	public readonly launchType: LaunchType;

	public readonly env: string[];

	public constructor( scope: Construct, id: string ) {
		super( scope, id );

		this.dockerRegistryAuthToken = this.node.tryGetContext( 'dockerRegistryAuthToken' );

		if ( !this.dockerRegistryAuthToken ) {
			Annotations.of( this ).addError( 'Context parameter "dockerRegistryAuthToken" is required' );
		}

		this.version = this.node.tryGetContext( 'version' ) ?? 'latest';

		this.env = ( this.node.tryGetContext( 'env' ) ?? '' ).split( ',' );

		this.launchType = LaunchType.EC2;
	}
}
