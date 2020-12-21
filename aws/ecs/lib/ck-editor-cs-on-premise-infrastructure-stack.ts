/*
 Copyright (c) 2016-2020, CKSource - Frederico Knabben. All rights reserved.
 */

import { StackProps, Stack, Construct, Tags } from '@aws-cdk/core';
import { RepositoryImage } from '@aws-cdk/aws-ecs';

import { ISecret } from '@aws-cdk/aws-secretsmanager';

import { StackConfig } from './stack-config';
import { Application } from './resource/application';
import { Database } from './resource/database';
import { Redis } from './resource/redis';
import { Storage } from './resource/storage';
import { Network } from './resource/network';
import { Utils } from './utils';
import { CsEnvironmentConfig } from './cs-environment-config';

export class CkEditorCsOnPremiseStack extends Stack {
	private readonly stackConfig: StackConfig;

	private readonly csEnvironmentConfig: CsEnvironmentConfig;

	private readonly network: Network;

	private readonly database: Database;

	private readonly storage: Storage;

	private readonly redis: Redis;

	private readonly repositoryImage: RepositoryImage;

	private readonly application: Application;

	public constructor( scope: Construct, id: string, props?: StackProps ) {
		super( scope, id, props );

		this.stackConfig = new StackConfig( this, 'StackConfig' );

		this.csEnvironmentConfig = new CsEnvironmentConfig( this, this.stackConfig.env );

		this.network = new Network( this, 'Network' );

		this.database = new Database( this, 'Database', { network: this.network } );

		this.storage = new Storage( this, 'Storage' );

		this.redis = new Redis( this, 'Redis', { network: this.network } );

		const repositoryCredentialValue: string = JSON.stringify( {
			username: 'ckeditor',
			password: this.stackConfig.dockerRegistryAuthToken
		} );
		const repositoryCredentials: ISecret = Utils.createUserProvidedSecret(
			this,
			'DockerRegistryToken',
			repositoryCredentialValue
		);

		this.repositoryImage = RepositoryImage.fromRegistry(
			`docker.cke-cs.com/cs:${ this.stackConfig.version }`, {
				credentials: repositoryCredentials
			} );

		this.application = new Application( this, 'Application', {
			stackConfig: this.stackConfig,
			repositoryImage: this.repositoryImage,
			network: this.network,
			database: this.database,
			redis: this.redis,
			storage: this.storage
		} );

		Tags.of( this ).add(
			'Application',
			'CKEditor - Cloud Server On-Premises Installation'
		);
	}
}
