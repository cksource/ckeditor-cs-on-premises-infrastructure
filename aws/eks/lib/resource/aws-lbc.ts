/*
 Copyright (c) 2016-2021, CKSource - Frederico Knabben. All rights reserved.
 */

import { Construct, StackProps } from '@aws-cdk/core';
import { Cluster, HelmChart, ServiceAccount } from '@aws-cdk/aws-eks';
import { Policy, PolicyDocument } from '@aws-cdk/aws-iam';

export interface AWSLoadBalancerControllerProps extends StackProps {
	cluster: Cluster;
	namespace: string;
}

export class AWSLoadBalancerController extends Construct {
	private readonly iamPolicy: Policy;

	private readonly serviceAccount: ServiceAccount;

	private readonly helmChart: HelmChart;

	public constructor( scope: Construct, id: string, props: AWSLoadBalancerControllerProps ) {
		super( scope, id );

		this.iamPolicy = new Policy( this, 'AWSLoadBalancerIAMPolicy', {
			policyName: 'AWSLoadBalancerIAMPolicy',
			document: new PolicyDocument( require( './aws-lbc-iam-policy.json' ) )
		} );

		this.serviceAccount = new ServiceAccount( this, 'aws-lbc', {
			cluster: props.cluster,
			name: 'aws-lbc',
			namespace: props.namespace
		} );

		this.serviceAccount.role.attachInlinePolicy( this.iamPolicy );

		this.helmChart = new HelmChart( this, 'AWSLBCHelmChart', {
			cluster: props.cluster,
			version: '1.2.0',
			chart: 'aws-load-balancer-controller',
			release: 'aws-load-balancer-controller',
			repository: 'https://aws.github.io/eks-charts',
			namespace: props.namespace,
			createNamespace: false,
			values: {
				'clusterName': `${ props.cluster.clusterName }`,
				'serviceAccount': {
					'create': false,
					'name': this.serviceAccount.serviceAccountName,
					'annotations': {
						'eks.amazonaws.com/role-arn': this.serviceAccount.role.roleArn
					}
				}
			}
		} );
	}
}
