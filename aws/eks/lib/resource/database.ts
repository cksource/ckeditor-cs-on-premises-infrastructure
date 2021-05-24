/*
 Copyright (c) 2016-2021, CKSource - Frederico Knabben. All rights reserved.
 */

import { Construct, RemovalPolicy } from '@aws-cdk/core';
import {
	AuroraMysqlEngineVersion,
	DatabaseCluster,
	DatabaseClusterEngine,
	Credentials
} from '@aws-cdk/aws-rds';
import {
	InstanceClass,
	InstanceSize,
	InstanceType,
	SubnetType
} from '@aws-cdk/aws-ec2';
import { ISecret, Secret } from '@aws-cdk/aws-secretsmanager';

import { Network } from './network';

interface IDatabaseProps {
  network: Network;
}

export class Database extends Construct {
	public static readonly SECRET_PASSWORD_KEY: string = 'password';

	public static readonly SECRET_USERNAME_KEY: string = 'username';

	public static readonly PORT: number = 3306;

	public readonly name: string = 'cs_on_premises';

	public readonly secret: ISecret;

	public readonly databaseCluster: DatabaseCluster;

	public constructor( scope: Construct, id: string, props: IDatabaseProps ) {
		super( scope, id );

		const credentialsTemplate: {[k: string]: string;} = {
			[ Database.SECRET_USERNAME_KEY ]: 'ckeditor'
		};

		this.secret = new Secret( this, 'DatabaseCredentials', {
			generateSecretString: {
				includeSpace: false,
				excludePunctuation: true,
				generateStringKey: Database.SECRET_PASSWORD_KEY,
				secretStringTemplate: JSON.stringify( credentialsTemplate )
			}
		} );

		this.databaseCluster = new DatabaseCluster( this, 'DatabaseCluster', {
			defaultDatabaseName: this.name,
			removalPolicy: RemovalPolicy.DESTROY,
			engine: DatabaseClusterEngine.auroraMysql( {
				version: AuroraMysqlEngineVersion.VER_2_09_0
			} ),
			credentials: Credentials.fromSecret( this.secret ),
			instanceProps: {
				vpc: props.network.vpc,
				vpcSubnets: { subnets: props.network.vpc.selectSubnets( { subnetType: SubnetType.ISOLATED } ).subnets },
				instanceType: InstanceType.of( InstanceClass.R5, InstanceSize.LARGE ),
				securityGroups: [ props.network.databaseSecurityGroup ]
			},
			port: Database.PORT,
			storageEncrypted: true
		} );
	}

	public get host(): string {
		return this.databaseCluster.clusterEndpoint.hostname;
	}
}
