# CKEditor Word Services On-Premises Helm chart

Use this Helm chart to provision CKEditor Word Services on your
Kubernetes cluster.

## Minimum requirements
- 1 CPU Core
- 512MB RAM
- Kubernetes 1.19+
- Helm v3

The default configuration of running this service requires the reservation of 1
CPU core and 512MB of RAM in the cluster. For more information about resources
usage look here:
https://ckeditor.com/docs/cs/latest/onpremises/docx-onpremises/requirements.html

## Installation

- create imagePullSecret for pulling images from CKEditor container registry,
  replace `xxx` with authentication token
```sh
kubectl create secret docker-registry docker-cke-cs-com \
    --docker-username "docx" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="xxx"
```

- install chart in cluster
>:warning: By default, the chart installs the CKEditor Word Services
>on-premises with the "latest" tag. If you are using this chart for a production
>environment, it's strongly recommended to change the container image tag to a
>numeric representation of the version you want to install.
```sh

helm install ckeditor-docx-converter ./ckeditor-docx-converter \
    --set image.tag="latest" \
    --set server.secret.data.LICENSE_KEY="" \
    --set server.ingress.hosts[0].host="test.example"
```

- validate installation by visiting the `/demo` page.


## Deleting

```sh
helm delete ckeditor-docx-converter
```
