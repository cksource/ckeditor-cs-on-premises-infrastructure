# CKEditor PDF Converter On-Premises Helm chart

Use this Helm chart to provision CKEditor PDF Converter on your
Kubernetes cluster.

## Requirements
- Kubernetes 1.25+
- Helm v3
- The prerequisites of CKEditor PDF Converter On-Premises, as listed in its
  [requirements](https://ckeditor.com/docs/cs/latest/onpremises/pdf-onpremises/requirements.html)

The chart's default `resources` request 1 CPU core and 512MB of RAM per pod,
so 2 CPU cores and 1GB of RAM with the default two replicas. Adjust them to the
resource guidance in the requirements linked above.

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
