/*
 Copyright (c) 2016-2021, CKSource - Frederico Knabben. All rights reserved.
 */

import { StackProps, Stack, Construct, Tags } from '@aws-cdk/core';
import { RepositoryImage } from '@aws-cdk/aws-ecs';

import { ISecret } from '@aws-cdk/aws-secretsmanager';

import { StackConfig } from './stack-config';
import { Database } from './resource/database';
import { Redis } from './resource/redis';
import { Storage } from './resource/storage';
import { Network } from './resource/network';
import { Utils } from './utils';
import { Application } from './resource/application';
import { Kubernetes } from './resource/kubernetes';
import { AWSLoadBalancerController } from './resource/aws-lbc';

export class CKEditorCSOnPremisesStack extends Stack {
	private readonly application: Application;

	private readonly awsLoadBalancerController: AWSLoadBalancerController;

	private readonly database: Database;

	private readonly kubernetes: Kubernetes;

	private readonly network: Network;

	private readonly redis: Redis;

	private readonly repositoryImage: RepositoryImage;

	private readonly stackConfig: StackConfig;

	private readonly storage: Storage;

	public constructor( scope: Construct, id: string, props?: StackProps ) {
		super( scope, id, props );

		this.stackConfig = new StackConfig( this, 'StackConfig' );

		this.network = new Network( this, 'Network' );

		this.database = new Database( this, 'Database', { network: this.network } );

		this.storage = new Storage( this, 'Storage', { network: this.network } );

		this.redis = new Redis( this, 'Redis', { network: this.network } );

		this.kubernetes = new Kubernetes( this, 'Kubernetes', {
			network: this.network
		} );

		this.awsLoadBalancerController = new AWSLoadBalancerController( this, 'AWSLoadBalancerController', {
			cluster: this.kubernetes.cluster,
			namespace: 'kube-system',
			network: this.network
		} );

		this.kubernetes.node.addDependency( this.awsLoadBalancerController );

		this.application = new Application( this, 'Application', {
			cluster: this.kubernetes.cluster,
			namespace: 'default',
			database: this.database,
			redis: this.redis,
			stackConfig: this.stackConfig,
			storage: this.storage
		} );

		this.application.node.addDependency( this.kubernetes, this.awsLoadBalancerController );

		Tags.of( this ).add(
			'Application',
			'CKEditor Collaboration Server On-Premises Installation'
		);
	}
}
