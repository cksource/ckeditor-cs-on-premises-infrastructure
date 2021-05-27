/*
 Copyright (c) 2016-2021, CKSource - Frederico Knabben. All rights reserved.
 */

import { Cluster, HelmChart, KubernetesManifest } from '@aws-cdk/aws-eks';
import { Construct, Fn, Stack } from '@aws-cdk/core';

import { Redis } from './redis';
import { Database } from './database';
import { Storage } from './storage';
import { StackConfig } from '../stack-config';
import { CSEnvironmentConfig } from '../cs-environment-config';

interface IApplicationProps {
	cluster: Cluster;
	database: Database;
	redis: Redis;
	stackConfig: StackConfig;
	storage: Storage;
	namespace: string;
}

export class Application extends Construct {
	private readonly helmChart: HelmChart;

	private readonly csEnvironmentConfig: CSEnvironmentConfig;
	
	private readonly registrySecret: KubernetesManifest;

	public constructor( scope: Construct, id: string, props: IApplicationProps ) {
		super( scope, id );

		this.csEnvironmentConfig = new CSEnvironmentConfig( this, props.stackConfig.env );

		const repositoryCredentialValue: string = JSON.stringify( {
			"auths": {
				"https://docker.cke-cs.com": {
					"username": 'cs',
					"password": props.stackConfig.dockerRegistryAuthToken
				}				
			}
		} );

		const buffer: Buffer = Buffer.from(repositoryCredentialValue);

		this.registrySecret = new KubernetesManifest(this, 'registrySecret', {
			cluster: props.cluster,
			manifest: [{
				kind: 'Secret',
				apiVersion: 'v1',
				type: 'kubernetes.io/dockerconfigjson',
				metadata: {
					name: 'docker-cke-cs-com',
					namespace: props.namespace
				},
				data: {
					'.dockerconfigjson': buffer.toString('base64'),
				}
			}]
		});

		this.helmChart = new HelmChart( scope, 'ApplicationHelmChart', {
			cluster: props.cluster,
			chart: './ckeditor-cs',
			namespace: props.namespace,
			release: 'ckeditor-cs',
			values: {
				'server': {
					'image': {
						'tag': props.stackConfig.version
					},
					'secret': {
						'data': {
							'DATABASE_HOST': props.database.host,
							'DATABASE_DATABASE': props.database.name,
							'DATABASE_PASSWORD': props.database.secret.secretValue,
							'DATABASE_USER': props.database.secret.secretValue,
							'STORAGE_DRIVER': 's3',
							'STORAGE_ENDPOINT': `${ props.storage.bucket.bucketRegionalDomainName }/storage`,
							'STORAGE_BUCKET': props.storage.bucket.bucketName,
							'STORAGE_REGION': Stack.of( this ).region,
							'COLLABORATION_STORAGE_DRIVER': 's3',
							'COLLABORATION_STORAGE_ENDPOINT': `${ props.storage.bucket.bucketRegionalDomainName }/collaboration_storage`,
							'COLLABORATION_STORAGE_BUCKET': props.storage.bucket.bucketName,
							'REDIS_CLUSTER_NODES': Fn.join( ':', [ props.redis.host, String( Redis.PORT ) ] ),
							...this.csEnvironmentConfig.toObject()
						}
					},
					'ingress': {
						'enabled': true,
						'annotations': {
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
	}
}
