/*
 Copyright (c) 2016-2021, CKSource - Frederico Knabben. All rights reserved.
 */

import { Cluster, KubernetesVersion } from '@aws-cdk/aws-eks';
import { Construct } from '@aws-cdk/core';
import { InstanceClass, InstanceSize, InstanceType, SubnetType } from '@aws-cdk/aws-ec2';

import { ManagedPolicy, Role, ServicePrincipal } from '@aws-cdk/aws-iam';

import { Network } from './network';

interface KubernetesProps {
	network: Network;
}

export class Kubernetes extends Construct {
	public readonly cluster: Cluster;

	private readonly clusterRole: Role;

	private readonly workerRole: Role;

	public constructor( scope: Construct, id: string, props: KubernetesProps ) {
		super( scope, id );

		this.clusterRole = new Role( this, 'ClusterRole', {
			assumedBy: new ServicePrincipal( 'eks.amazonaws.com' ),
			managedPolicies: [
				ManagedPolicy.fromAwsManagedPolicyName( 'AmazonEKSClusterPolicy' ),
				ManagedPolicy.fromAwsManagedPolicyName( 'AmazonEKSVPCResourceController' )
			]
		} );

		this.cluster = new Cluster( scope, 'defaultEksCluster', {
			defaultCapacity: 0,
			role: this.clusterRole,
			version: KubernetesVersion.V1_19,
			vpc: props.network.vpc
		} );

		this.workerRole = new Role( this, 'WorkerRole', {
			assumedBy: new ServicePrincipal( 'ec2.amazonaws.com' ),
			managedPolicies: [
				ManagedPolicy.fromAwsManagedPolicyName( 'AmazonEKSWorkerNodePolicy' ),
				ManagedPolicy.fromAwsManagedPolicyName( 'AmazonEKS_CNI_Policy' ),
				ManagedPolicy.fromAwsManagedPolicyName( 'AmazonEKSVPCResourceController' )
			]
		} );

		this.cluster.addNodegroupCapacity( 'defaultNodegroupCapacity', {
			subnets: props.network.vpc.selectSubnets( { subnetType: SubnetType.PRIVATE } ),
			nodeRole: this.workerRole,
			minSize: 2,
			maxSize: 3,
			instanceTypes: [
				InstanceType.of( InstanceClass.C5, InstanceSize.LARGE )
			]
		} );

		props.network.allowDatabaseConnectionsFrom( this.cluster );
		props.network.allowRedisConnectionsFrom( this.cluster );
	}
}
