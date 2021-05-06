# CKEditor Collaboration Server On-Premise Kubernetes Helm chart example

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
helm install -f example-configuration-file.yaml ckeditor-cs kubernetes/helm/ckeditor-cs
```

## Verify

By default our helm chart is configured to use Kubernetes health checks to
determine if deployed service works properly, however you can confirm whole set of server features with our e2e tests

```sh
# Your container registry username
DOCKER_USERNAME=
# Your container registry authentication token
DOCKER_TOKEN=
# CKEditor Collaboration Server E2E tests version
VERSION=latest

docker login -u $DOCKER_USERNAME -p $DOCKER_TOKEN docker.cke-cs.com/cs-tests:$VERSION

docker run \
-e APPLICATION_ENDPOINT="$(kubectl get in)" \
-e ENVIRONMENTS_MANAGEMENT_SECRET_KEY="[your_env_management_secret_key]" \
docker.cke-cs.com/cs-tests:$VERSION

```
Documentation: [Testing onpremise](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/testing/docker.html)
## Troubleshooting

### Websocket connection problem

Make sure your ingress controller and load balancer configuration supports stable
websocket connection. To check if your infrastructure is correctly configured
compare results of running e2e tests mentioned above against:
- load balancer/ingress controller endpoint 
- `kubectl port-forward` endpoint