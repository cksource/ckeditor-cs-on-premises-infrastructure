/*
 Copyright (c) 2016-2021, CKSource - Frederico Knabben. All rights reserved.
 */

import { CfnJson, Construct, Fn, StackProps } from '@aws-cdk/core';
import { Cluster, HelmChart, ServiceAccount } from '@aws-cdk/aws-eks';
import { FederatedPrincipal, Policy, PolicyDocument } from '@aws-cdk/aws-iam';

import { Network } from './network';

export interface AWSLoadBalancerControllerProps extends StackProps {
	cluster: Cluster;
	namespace: string;
	network: Network;
}

export class AWSLoadBalancerController extends Construct {
	private readonly iamPolicy: Policy;

	private readonly serviceAccount: ServiceAccount;

	private readonly helmChart: HelmChart;

	private readonly oidcPrincipal: FederatedPrincipal;

	public constructor( scope: Construct, id: string, props: AWSLoadBalancerControllerProps ) {
		super( scope, id );

		this.iamPolicy = new Policy( this, 'AWSLoadBalancerIAMPolicy', {
			policyName: 'AWSLoadBalancerIAMPolicy',
			document: PolicyDocument.fromJson( require( './aws-lbc-iam-policy.json' ) )
		} );

		this.serviceAccount = new ServiceAccount( this, 'aws-lbc', {
			cluster: props.cluster,
			name: 'aws-lbc',
			namespace: props.namespace
		} );

		this.serviceAccount.role.attachInlinePolicy( this.iamPolicy );

		const clusterId = Fn.select(4, Fn.split('/', props.cluster.clusterOpenIdConnectIssuerUrl))

        this.oidcPrincipal = new FederatedPrincipal(
            props.cluster.openIdConnectProvider.openIdConnectProviderArn,
            {
                StringEquals: new CfnJson(this, "FederatedPrincipalCondition", {
                    value: {
                        [`oidc.eks.${props.network.vpc.env.region}.amazonaws.com/id/${clusterId}:aud`]: "sts.amazonaws.com",
                        [`oidc.eks.${props.network.vpc.env.region}.amazonaws.com/id/${clusterId}:sub`]: `system:serviceaccount:kube-system:${this.serviceAccount.serviceAccountName}`
                    }
                })
            }, "sts:AssumeRoleWithWebIdentity"
		)

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
