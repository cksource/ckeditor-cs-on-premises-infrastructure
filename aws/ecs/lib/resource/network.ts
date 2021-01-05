/*
 Copyright (c) 2016-2020, CKSource - Frederico Knabben. All rights reserved.
 */

import { Construct } from '@aws-cdk/core';
import {
	SubnetType,
	Vpc,
	IVpc,
	GatewayVpcEndpoint,
	GatewayVpcEndpointAwsService,
	SecurityGroup,
	Port,
	IConnectable
} from '@aws-cdk/aws-ec2';

import { Database } from './database';
import { Redis } from './redis';

export class Network extends Construct {
	public readonly vpc: IVpc;

	public readonly s3Endpoint: GatewayVpcEndpoint;

	public readonly redisSecurityGroup: SecurityGroup;

	public readonly databaseSecurityGroup: SecurityGroup;

	public constructor( scope: Construct, id: string ) {
		super( scope, id );

		this.vpc = new Vpc( this, 'Vpc', {
			subnetConfiguration: [
				{ cidrMask: 24, name: 'public-subnet', subnetType: SubnetType.PUBLIC },
				{ cidrMask: 24, name: 'application-subnet', subnetType: SubnetType.PRIVATE },
				{ cidrMask: 26, subnetType: SubnetType.ISOLATED, name: 'data-subnet' }
			]
		} );

		this.s3Endpoint = this.vpc.addGatewayEndpoint( 'S3BucketEndpoint', { service: GatewayVpcEndpointAwsService.S3 } );

		this.redisSecurityGroup = new SecurityGroup( this, 'RedisSecurityGroup', {
			securityGroupName: 'redis-sg',
			vpc: this.vpc
		} );

		/**
		 * @see {@link https://redis.io/topics/cluster-tutorial#redis-cluster-tcp-ports}
		 */
		this.redisSecurityGroup.connections.allowInternally( Port.tcp( Redis.PORT + 10000 ) );

		this.databaseSecurityGroup = new SecurityGroup( this, 'DatabaseSecurityGroup', {
			securityGroupName: 'database-sg',
			vpc: this.vpc
		} );
	}

	public allowRedisConnectionsFrom( resource: IConnectable ): void {
		this.redisSecurityGroup.connections.allowFrom( resource, Port.tcp( Redis.PORT ) );
	}

	public allowDatabaseConnectionsFrom( resource: IConnectable ): void {
		this.databaseSecurityGroup.connections.allowFrom( resource, Port.tcp( Database.PORT ) );
	}
}
