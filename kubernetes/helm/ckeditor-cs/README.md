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

The default configuration of running this service requires the reservation of 2
CPU cores and 1GB of RAM in the cluster. For more information about resources
usage look here:
https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/requirements.html#docker

## Installation

- create imagePullSecret for pulling images from CKEditor container registry,
  replace `xxx` with authentication token
```sh
kubectl create secret docker-registry docker-cke-cs-com \
    --docker-username "cs" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="xxx"
```

- install chart in cluster
>:warning: By default, the chart installs the Ckeditor Collaboration Server
>on-premises with the "latest" tag. If you are using this chart for a production
>environment, it's strongly recommended to change the container image tag to a
>numeric representation of the version you want to install.
```sh

helm install ckeditor-cs ./ckeditor-cs \
    --set image.tag="latest" \
    --set server.secret.data.DATABASE_HOST="" \
    --set server.secret.data.DATABASE_USER="" \
    --set server.secret.data.DATABASE_PASSWORD="" \
    --set server.secret.data.REDIS_HOST="" \
    --set server.secret.data.ENVIRONMENTS_MANAGEMENT_SECRET_KEY="" \
    --set server.secret.data.LICENSE_KEY="" \
    --set server.secret.data.STORAGE_DRIVER="" \
    --set server.secret.data.STORAGE_LOCATION="" \
    --set server.ingress.hosts[0].host="test.example"
```

- validate installation by running tests
```sh
./../test-deployment.sh
```

## Deleting

```sh
helm delete ckeditor-cs
```
