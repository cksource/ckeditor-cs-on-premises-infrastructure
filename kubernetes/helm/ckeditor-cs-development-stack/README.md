# CKEditor Collaboration Server On-Premise development stack Helm chart

>:warning: **Not for production purposes!** This configuration is insecure, not persistent and its purpose is testing only.

Helm chart for fast deployment of Collaboration Server On-Premises in Kubernetes with MySQL database and Redis cluster.

## Minimum requirements
- 2 CPU Core
- 1024MB RAM
- Kubernetes 1.19+
- Helm v3

## Getting started

Download repository:
```sh
git clone git@github.com:cksource/ckeditor-cs-on-premises-infrastructure.git
cd ckeditor-cs-on-premises-infrastructure/kubernetes/helm/ckeditor-cs-stack 
```

Create imagePullSecret for pulling container images in cluster from CKEditor container registry
```sh
# Your container registry authentication token
REGISTRY_TOKEN=

kubectl create secret docker-registry docker-cke-cs-com --docker-username cs --docker-server https://docker.cke-cs.com --docker-password $REGISTRY_TOKEN
```

## Installation

Update `values.yaml` file with your ingress hostname and licence key. Next install chart in your kubernetes cluster:

```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency build
helm install ckeditor-cs-stack .
```
## Local environment
