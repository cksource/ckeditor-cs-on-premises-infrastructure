# CKEditor Collaboration Server On-Premises Azure Terraform modules

Use this Terraform module to provision infrastructure hosted in Microsoft Azure
for CKEditor Collaboration Server. Modules are separated into two. One for
provisioning the infrastructure needed to run the service and the second
deploying service onto that infrastructure.

**Note**: These modules are made for Terraform. If you haven't worked with it
before, we highly recommend getting familiar with it first:
https://www.terraform.io/intro

## List of modules

Short description of every module in this directory:

### [service](service)

Module provisioning the CKEditor Collaboration Server on top of Azure AKS by
using Helm chart. You can find more information about the used Helm chart here:
[kubernetes/helm/ckeditor-cs](/kubernetes//helm/ckeditor-cs/)

### [infrastructure](infrastructure)

The module is responsible for provisioning all elements of infrastructure
required to run the CKEditor Collaboration Server on Microsoft Azure. It creates
the whole infrastructure in one dedicated resource group for separation from the
rest of the resources in the Azure account.

## Quickstart

Check how can you utilize those modules in our [example](example-usage).

## Infrastructure overview

![CKEditor-cs Azure infrastructure diagram](diagram.jpg)

### Azure Virtual Network

The private network is hosted inside Azure infrastructure. Contains five subnets
for:
- 10.0.0.0/22 AKS node pool
- 10.0.4.0/22 MySQL
- 10.0.8.0/22 Storage account
- 10.0.12.0/22 Redis private endpoint
- 10.0.16.0/22 Application Gateway

### Azure Private Endpoint

A network interface connecting privately Redis Cache cluster to the Azure
virtual network.

### Azure AKS

Managed Kubernetes cluster hosted inside the virtual network with Azure Log
Analytics enabled. The cluster has enabled Application Gateway integration for
managed provisioning of Ingress controller.

### Azure Redis Cache

Azure managed Redis database cluster accessible only through the Azure Private
Endpoint in Virtual Network.

### Azure MySQL Flexible Server

Azure managed MySQL database cluster with automatic backups enabled. Backups
have retention configured to 7 days.

### Azure Application Gateway

Provisioned by AKS integration load balancing service. Used for exposing the
CKEditor Collaboration Server outside the virtual network.

### Azure Storage Account and Container

Private encrypted blob storage managed by Azure.
