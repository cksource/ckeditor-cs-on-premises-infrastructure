# CKEditor Collaboration Server On-Premises Helm chart

Use this Helm chart to provision CKEditor Collaboration Server on your
Kubernetes cluster.

## Minimum requirements
- 2 CPU Core
- 1024MB RAM
- One of the following SQL databases:
  - MySQL 5.6/5.7
  - PostgreSQL min. 12.0
- External Redis cluster 3.2.6 or newer
- Kubernetes 1.19+
- Helm v3

Default configuration of running this service requires reservation of 2 CPU
cores and 1GB of RAM in cluster.

For detailed specification of CKEditor Collaboration Server follow instructions
from [requirements
documentation](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/requirements.html).

## Getting started

Create imagePullSecret for CKEditor container registry
```sh
kubectl create secret docker-registry docker-cke-cs-com --docker-username cs --docker-server https://docker.cke-cs.com --docker-password=xxx
```

Download repository containing helm chart
```
git clone git@github.com:cksource/ckeditor-cs-on-premises-infrastructure.git
cd ckeditor-cs-on-premises-infrastructure
```

## Configuration

Create your own configuration based on `values.yaml` file
> :warning: **If you want to store configuration**: Make sure your environment
> variables are secure before saving them in external service. You can use
> [SOPS](https://github.com/mozilla/sops) for encrypting specific parts of yaml
> file.

Environment variables mentioned in configuration file are an absolute minimum to run the service. Visit documentation for whole list of configuration options:

https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/installation/docker.html#docker-container-environment-variables

## Installation

```sh
# Install helm chart in your kubernetes cluster
helm install ckeditor-cs kubernetes/helm/ckeditor-cs -f path-to-your-configuration-file.yaml
```

## Verify installation

By default our helm chart is configured to use Kubernetes health checks to
determine if deployed service works properly, however you can confirm whole set of server features with our e2e tests

```sh
kubectl run ckeditor-cs-tests -i --rm \
  --image docker.cke-cs.com/cs-tests:"$(kubectl get deployments.apps ckeditor-cs-server -o json | jq -r '.spec.template.spec.containers[0].image' | sed 's/.*://')" \
  --env APPLICATION_ENDPOINT="$(kubectl get ingresses.networking.k8s.io ckeditor-cs-server -o json | jq -r '.spec.rules[0].host' | sed 's|^|http://|')" \
  --env ENVIRONMENTS_MANAGEMENT_SECRET_KEY="$(kubectl get secret ckeditor-cs-server -o json | jq -r '.data.ENVIRONMENTS_MANAGEMENT_SECRET_KEY' | base64 -d)" \
  --overrides='{ "spec": { "imagePullSecrets": [{"name": "docker-cke-cs-com"}] } }' \
  --restart='Never'
```
Documentation: [Testing onpremise](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/testing/docker.html)
