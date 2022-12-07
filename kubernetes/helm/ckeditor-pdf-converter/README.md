# CKEditor PDF Converter On-Premises Helm chart

Use this Helm chart to provision CKEditor PDF Converter on your
Kubernetes cluster.

## Minimum requirements
- 2 CPU Cores
- 1024MB RAM
- Kubernetes 1.19+
- Helm v3

The default configuration for running this service requires the reservation of
2 CPU cores and 1024MB of RAM in the cluster. For more information about resources
usage look here:
https://ckeditor.com/docs/cs/latest/onpremises/pdf-onpremises/requirements.html

## Installation

- create imagePullSecret for pulling images from the CKEditor container registry,
  replace `xxx` with the authentication token

```sh
kubectl create secret docker-registry docker-cke-cs-com \
    --docker-username "pdf" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="xxx"
```

- install chart in the cluster

>:warning: By default, the chart installs the CKEditor PDF Converter
>on-premises with the "latest" tag. If you are using this chart for a production
>environment, it is strongly recommended to change the container image tag to a
>numeric representation of the version you want to install.

```sh

helm install ckeditor-pdf-converter ./ckeditor-pdf-converter \
    --set image.tag="latest" \
    --set server.secret.data.LICENSE_KEY="" \
    --set ingress.hosts[0].host="test.example" \
    --set ingress.enabled=true
```

- validate installation by visiting the `/demo` page.

## Deleting

```sh
helm delete ckeditor-pdf-converter
```
