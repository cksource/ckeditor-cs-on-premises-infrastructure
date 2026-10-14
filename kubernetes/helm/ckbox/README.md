# CKBox On-Premises Helm chart

Use this Helm chart to provision CKBox on your Kubernetes cluster.

## Requirements
- Kubernetes 1.25+
- Helm v3
- The SQL database, Redis-compatible store and other prerequisites of CKBox
  On-Premises, as listed in its [requirements](https://ckeditor.com/docs/cs/latest/onpremises/ckbox-onpremises/requirements.html)

The chart does not set `resources.requests` by default. Set them according to
the resource guidance in the requirements linked above.

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
