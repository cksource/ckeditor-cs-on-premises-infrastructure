# CKEditor Collaboration Server On-Premise stack Helm chart

>:warning: **Not for production purposes!** This configuration is insecure, not persistent and its purpose is testing only.

Helm chart for fast deployment of CKEditor Cloud Services in Kubernetes with MySQL database and redis cluster.

## Getting started

Download repository:
```sh
git clone git@github.com:cksource/ckeditor-cs-on-premises-infrastructure.git
cd ckeditor-cs-on-premises-infrastructure/kubernetes/helm/ckeditor-cs-stack 
```

Create imagePullSecret for CKEditor container registry
```sh
# Your container registry username
REGISTRY_USERNAME=
# Your container registry authentication token
REGISTRY_TOKEN=

kubectl create secret docker-registry docker-cke-cs-com --docker-username $REGISTRY_USERNAME --docker-password $REGISTRY_TOKEN --docker-server https://docker.cke-cs.com
```

## Installation

Update `values.yaml` file with your ingress hostname and licence key. Next install chart in your kubernetes cluster:

```sh
helm dependency build
helm install ckeditor-cs-stack .
```

## Verify installation

```sh
# Get ingress hostname
APPLICATION_ENDPOINT="$(kubectl get ingresses.networking.k8s.io ckeditor-cs -o json | jq -r '.spec.rules[0].host' | sed 's|^|http://|')"
# Get CKEditor Cloud Services version
VERSION="$(kubectl get deployments.apps ckeditor-cs -o json | jq -r '.spec.template.spec.containers[0].image' | sed 's/.*://')"
# Secret key
ENVIRONMENTS_MANAGEMENT_SECRET_KEY=secret

kubectl run ckeditor-cs-tests -i \
  --image docker.cke-cs.com/cs-tests:$VERSION \
  --env APPLICATION_ENDPOINT="$APPLICATION_ENDPOINT" \
  --env ENVIRONMENTS_MANAGEMENT_SECRET_KEY="$ENVIRONMENTS_MANAGEMENT_SECRET_KEY" \
  --overrides='{ "spec": { "imagePullSecrets": [{"name": "docker-cke-cs-com"}] } }' \
  --restart='Never'
```
Documentation: [Testing onpremise](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/testing/docker.html)
