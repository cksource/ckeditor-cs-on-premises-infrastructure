/*
 Copyright (c) 2016-2020, CKSource - Frederico Knabben. All rights reserved.
 */

import { Construct, Duration, Fn, Stack } from '@aws-cdk/core';
import { ApplicationLoadBalancedEc2Service } from '@aws-cdk/aws-ecs-patterns';
import {
	Cluster,
	ContainerDefinition,
	Ec2TaskDefinition,
	LaunchType,
	LogDrivers,
	PlacementStrategy,
	Protocol,
	RepositoryImage,
	Secret,
	TaskDefinition
} from '@aws-cdk/aws-ecs';
import { RetentionDays } from '@aws-cdk/aws-logs';
import { InstanceClass, InstanceSize, InstanceType, Port } from '@aws-cdk/aws-ec2';
import { ApplicationLoadBalancer, TargetGroupBase } from '@aws-cdk/aws-elasticloadbalancingv2';
import { AutoScalingGroup } from '@aws-cdk/aws-autoscaling';

import { Redis } from './redis';
import { Database } from './database';
import { Storage } from './storage';
import { Network } from './network';
import { StackConfig } from '../stack-config';
import { CsEnvironmentConfig } from '../cs-environment-config';

interface IApplicationProps {
	stackConfig: StackConfig;
	network: Network;
	database: Database;
	redis: Redis;
	storage: Storage;
	repositoryImage: RepositoryImage;
}

export class Application extends Construct {
	private readonly taskDefinition: TaskDefinition;

	private readonly containerDefinition: ContainerDefinition;

	private readonly csEnvironmentConfig: CsEnvironmentConfig;

	public readonly cluster: Cluster;

	public readonly autoScalingGroup: AutoScalingGroup

	private readonly loadBalancedEc2Service: ApplicationLoadBalancedEc2Service;

	public constructor( scope: Construct, id: string, props: IApplicationProps ) {
		super( scope, id );

		this.csEnvironmentConfig = new CsEnvironmentConfig( this, props.stackConfig.env );

		this.cluster = new Cluster( this, 'EcsCluster', { vpc: props.network.vpc } );

		this.autoScalingGroup = this.cluster.addCapacity( 'DefaultAutoScalingGroupCapacity', {
			instanceType: InstanceType.of( InstanceClass.C5, InstanceSize.LARGE ),
			desiredCapacity: 2,
			taskDrainTime: Duration.seconds( 0 )
		} );

		this.taskDefinition = new Ec2TaskDefinition( this, 'TaskDefinition' );

		this.containerDefinition = this.taskDefinition.addContainer( 'CloudServicesContainer', {
			image: props.repositoryImage,
			environment: {
				DATABASE_HOST: props.database.host,
				DATABASE_DATABASE: props.database.name,
				STORAGE_DRIVER: 's3',
				STORAGE_ENDPOINT: props.storage.bucket.bucketDomainName,
				STORAGE_BUCKET: props.storage.bucket.bucketName,
				STORAGE_REGION: Stack.of( this ).region,
				REDIS_CLUSTER_NODES: Fn.join( ':', [ props.redis.host, String( Redis.PORT ) ] ),
				...this.csEnvironmentConfig.toObject()
			},
			secrets: {
				DATABASE_PASSWORD: Secret.fromSecretsManager( props.database.secret, Database.SECRET_PASSWORD_KEY ),
				DATABASE_USER: Secret.fromSecretsManager( props.database.secret, Database.SECRET_USERNAME_KEY )
			},
			memoryLimitMiB: 2048,
			logging: LogDrivers.awsLogs( { streamPrefix: 'ckeditor/cs', logRetention: RetentionDays.TWO_MONTHS } )
		} );

		const applicationHttpPort: number = Number( this.csEnvironmentConfig.get( 'APPLICATION_HTTP_PORT' ) );

		this.containerDefinition.addPortMappings( {
			containerPort: applicationHttpPort,
			hostPort: applicationHttpPort,
			protocol: Protocol.TCP
		} );

		props.storage.bucket.grantReadWrite( this.taskDefinition.taskRole );

		if ( props.stackConfig.launchType === LaunchType.EC2 ) {
			this.loadBalancedEc2Service = new ApplicationLoadBalancedEc2Service(
				this,
				'LoadBalancedEc2Service',
				{
					taskDefinition: this.taskDefinition,
					cluster: this.cluster,
					publicLoadBalancer: true
				}
			);

			this.loadBalancedEc2Service.service.addPlacementStrategies(
				PlacementStrategy.spreadAcrossInstances(),
				PlacementStrategy.packedByCpu()
			);
		}

		this.targetGroup.configureHealthCheck( { path: '/health' } );

		this.cluster.connections.allowFrom( this.loadBalancer, Port.allTraffic() );
		props.network.allowRedisConnectionsFrom( this.cluster );
		props.network.allowDatabaseConnectionsFrom( this.cluster );
	}

	public get loadBalancer(): ApplicationLoadBalancer {
		return this.loadBalancedEc2Service.loadBalancer;
	}

	public get targetGroup(): TargetGroupBase {
		return this.loadBalancedEc2Service.targetGroup;
	}
}
