import { Cluster, HelmChart, KubernetesVersion, OpenIdConnectProvider } from '@aws-cdk/aws-eks';
import { Construct, Fn, IgnoreStrategy, Stack } from '@aws-cdk/core';

import { InstanceClass, InstanceSize, InstanceType } from '@aws-cdk/aws-ec2';

import { Redis } from './redis';
import { Database } from './database';
import { Storage } from './storage';
import { Network } from './network';
import { StackConfig } from '../stack-config';
import { CSEnvironmentConfig } from '../cs-environment-config';

interface IApplication2Props {
	stackConfig: StackConfig;
	network: Network;
	database: Database;
	redis: Redis;
	storage: Storage;
}

export class Application2 extends Construct {
	public readonly cluster: Cluster;

	private readonly helmChart: HelmChart;

	private readonly csEnvironmentConfig: CSEnvironmentConfig;

	private readonly openIdConnectProvider: OpenIdConnectProvider;

	public constructor( scope: Construct, id: string, props: IApplication2Props ) {
		super( scope, id );

		this.cluster = new Cluster( scope, 'defaultEksCluster', {
			defaultCapacity: 0,
			version: KubernetesVersion.V1_19,
			vpc: props.network.vpc
		} );

		this.cluster.addNodegroupCapacity( 'defaultNodegroupCapacity', {
			minSize: 2,
			maxSize: 3,
			instanceTypes: [
				InstanceType.of( InstanceClass.C5, InstanceSize.LARGE )
			]
		} );

		this.openIdConnectProvider = new OpenIdConnectProvider( this, 'defaultOpenIdConnectProvider', {
			url: this.cluster.openIdConnectProvider.openIdConnectProviderIssuer
		} );

		this.helmChart = new HelmChart( scope, 'defaultHelmChart', {
			cluster: this.cluster,
			chart: './../../kubernetes/helm/ckeditor-cs',
			values: {
				server: {
					secret: {
						data: {
							DATABASE_HOST: props.database.host,
							DATABASE_DATABASE: props.database.name,
							DATABASE_PASSWORD: '',
							DATABASE_USER: '',
							STORAGE_DRIVER: 's3',
							STORAGE_ENDPOINT: `${ props.storage.bucket.bucketRegionalDomainName }/storage`,
							STORAGE_BUCKET: props.storage.bucket.bucketName,
							STORAGE_REGION: Stack.of( this ).region,
							COLLABORATION_STORAGE_DRIVER: 's3',
							COLLABORATION_STORAGE_ENDPOINT: `${ props.storage.bucket.bucketRegionalDomainName }/collaboration_storage`,
							COLLABORATION_STORAGE_BUCKET: props.storage.bucket.bucketName,
							REDIS_CLUSTER_NODES: Fn.join( ':', [ props.redis.host, String( Redis.PORT ) ] ),
							...this.csEnvironmentConfig.toObject()
						}
					},
					ingress: {
						enabled: true,
						annotations: {
							'kubernetes.io/ingress.class': 'alb',
							'alb.ingress.kubernetes.io/scheme': 'internet-facing',
							'alb.ingress.kubernetes.io/target-group-attributes':
								'stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=60',
							'alb.ingress.kubernetes.io/target-type': 'ip'
						}
					}
				}
			}
		} );

		props.network.allowDatabaseConnectionsFrom( this.cluster );
		props.network.allowRedisConnectionsFrom( this.cluster );
	}
}
