# CKEditor Collaboration Server On-Premise Helm chart

Use this Helm chart to provision CKEditor Collaboration Server on your
Kubernetes cluster.

## Minimum requirements
- 1 CPU Core
- 512 MB RAM
- External SQL database:
  - MySQL 5.6/5.7
  - PostgreSQL min. 12.0
- External Redis cluster 3.2.6 or newer
- Kubernetes 1.19+
- Helm v3

For detailed specification of CKEditor Collaboration Server follow instructions
from [requirements
documentation](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/requirements.html).

## Getting started

Create imagePullSecret for CKEditor container registry
```sh
# Your container registry username
REGISTRY_USERNAME=
# Your container registry authentication token
REGISTRY_TOKEN=

kubectl create secret docker-registry docker-cke-cs-com --docker-username $REGISTRY_USERNAME --docker-password $REGISTRY_TOKEN --docker-server https://docker.cke-cs.com
```

## Installation

Create your own configuration based on `values.yaml` file and install chart on
cluster
> :warning: **If you want to store configuration**: Make sure your environment
> variables are secure before saving them in external service. You can use
> [SOPS](https://github.com/mozilla/sops) for encrypting specific parts of yaml
> file.

```sh
# Clone repository containing helm charts
git clone git@github.com:cksource/ckeditor-cs-on-premises-infrastructure.git
cd ckeditor-cs-on-premises-infrastructure
# Install helm chart in your kubernetes cluster
helm install ckeditor-cs kubernetes/helm/ckeditor-cs -f path-to-your-configuration-file.yaml
```

## Verify installation

By default our helm chart is configured to use Kubernetes health checkts to
determine if deployed service works properly, however you can confirm whole set of server features with our e2e tests

```sh
# Get ingress hostname
APPLICATION_ENDPOINT="$(kubectl get ingresses.networking.k8s.io ckeditor-cs -o json | jq -r '.spec.rules[0].host' | sed 's|^|http://|')"
# Get CKEditor Cloud Services version
VERSION="$(kubectl get deployments.apps ckeditor-cs -o json | jq -r '.spec.template.spec.containers[0].image' | sed 's/.*://')"
# Secret key
ENVIRONMENTS_MANAGEMENT_SECRET_KEY="$(kubectl get secret ckeditor-cs -o json | jq -r '.data.ENVIRONMENTS_MANAGEMENT_SECRET_KEY' | base64 -d)"

kubectl run ckeditor-cs-tests -i --rm \
  --image docker.cke-cs.com/cs-tests:$VERSION \
  --env APPLICATION_ENDPOINT="$APPLICATION_ENDPOINT" \
  --env ENVIRONMENTS_MANAGEMENT_SECRET_KEY="$ENVIRONMENTS_MANAGEMENT_SECRET_KEY" \
  --overrides='{ "spec": { "imagePullSecrets": [{"name": "docker-cke-cs-com"}] } }' \
  --restart='Never'
```
Documentation: [Testing onpremise](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/testing/docker.html)
