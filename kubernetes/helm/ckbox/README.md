# CKBox On-Premises Helm chart

Use this Helm chart to provision CKBox on your Kubernetes cluster.

## Minimum requirements
- 2 CPU Core
- 1024MB RAM
- One of the following SQL databases:
  - MySQL 8.0 or newer
  - PostgreSQL min. 12.0
- External Redis cluster 3.2.6 or newer
- Kubernetes 1.19+
- Helm v3

The default configuration of running this service requires the reservation of 2
CPU cores and 1GB of RAM in the cluster. For more information about resources
usage look here:
https://ckeditor.com/docs/cs/latest/onpremises/ckbox-onpremises/requirements.html

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
>:warning: By default, the chart installs the CKBox on-premises with the
>"latest" tag. If you are using this chart for a production environment, it's
>strongly recommended to change the container image tag to a numeric
>representation of the version you want to install.
```sh

helm install ckbox ./ckbox \
    --set image.tag="latest" \
    --set 'ingress.hosts[0].host'="test.example"
    --set secret.data.DATABASE_HOST="" \
    --set secret.data.DATABASE_PASSWORD="" \
    --set secret.data.DATABASE_USER="" \
    --set secret.data.ENVIRONMENTS_MANAGEMENT_SECRET_KEY="" \
    --set secret.data.LICENSE_KEY="" \
    --set secret.data.REDIS_HOST="" \
    --set secret.data.STORAGE_DRIVER="" \
```

## Deleting

```sh
helm delete ckbox
```
