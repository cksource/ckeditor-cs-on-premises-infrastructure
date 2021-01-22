/*
 Copyright (c) 2016-2020, CKSource - Frederico Knabben. All rights reserved.
 */

import { Connections, SubnetType } from '@aws-cdk/aws-ec2';
import { Construct } from '@aws-cdk/core';
import { CfnReplicationGroup, CfnSubnetGroup } from '@aws-cdk/aws-elasticache';

import { Network } from './network';

interface IRedisProps {
	network: Network;
}

export class Redis extends Construct {
	public static readonly PORT: number = 6379;

	public readonly connections: Connections;

	private readonly redisSubnetGroup: CfnSubnetGroup;

	private readonly replicationGroup: CfnReplicationGroup;

	public constructor( scope: Construct, id: string, props: IRedisProps ) {
		super( scope, id );

		this.redisSubnetGroup = new CfnSubnetGroup(
			this,
			'RedisClusterPrivateSubnetGroup',
			{
				cacheSubnetGroupName: 'redis-isolated-subnet',
				subnetIds: props.network.vpc.selectSubnets( { subnetType: SubnetType.ISOLATED } ).subnetIds,
				description: 'CKEditor redis subnets'
			}
		);

		this.replicationGroup = new CfnReplicationGroup( this, 'RedisReplicaGroup', {
			engine: 'redis',
			engineVersion: '6.x',
			cacheNodeType: 'cache.m5.large',
			replicasPerNodeGroup: 1,
			numNodeGroups: 2,
			automaticFailoverEnabled: true,
			autoMinorVersionUpgrade: true,
			replicationGroupDescription: 'CKEditor Collaboration Server Redis Cluster',
			cacheSubnetGroupName: this.redisSubnetGroup.ref,
			transitEncryptionEnabled: false,
			atRestEncryptionEnabled: true,
			securityGroupIds: [ props.network.redisSecurityGroup.securityGroupId ],
			port: Redis.PORT
		} );
	}

	public get host(): string {
		return this.replicationGroup.attrConfigurationEndPointAddress;
	}
}
