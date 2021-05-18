# CKEditor Collaboration Server On-Premises development stack Helm chart

>:warning: **Not for production purposes!** This configuration is insecure, not
>persistent and its purpose is testing only.

Helm chart for fast deployment of Collaboration Server On-Premises in Kubernetes
with MySQL database and Redis cluster.

## Minimum requirements
- 4 CPU Core
- 4096MB RAM
- Kubernetes 1.19+
- Helm v3

## Quick start

Create imagePullSecret for pulling images from CKEditor container registry,
replace `xxx` with authentication token
```sh
kubectl create secret docker-registry docker-cke-cs-com \
    --docker-username "cs" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="xxx"
```

Installing helm chart in cluster:
```sh
cd ckeditor-cs-development-stack
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm dependency update
helm install ckeditor-cs .
```

Deleting it:
```sh
helm delete ckeditor-cs
```
## Local environment

For local minikube environment there is a `init.sh` script located in helm chart
directory. The script was made with MacOS in mind and provisions minikube
environment. Quick start:

- run `init.sh` script for minikube configuration provisioning.
```
./init.sh
```

- edit `dev.values.yaml` file with license key:
```yaml
ckeditor-cs:
  server:
    secret:
      data:
        LICENSE_KEY: xxx
```

- install chart in cluster
```sh
helm install ckeditor-cs . -f dev.values.yaml
```

- test installation
```sh
./../test-deployment.sh
```

By default development environment can be accessed by http://ckeditor-cs.organization.test address.

## Deleting installation

```sh
helm delete ckeditor-cs
```

## Common issues

1. First start can result in few CrashLoopBackOff error in server container,
it's normal and the cause is in MySQL startup time. However it should be running
correctly after short time.

2. It is possible to encounter problems with nginx ingress validation in
minikube environment, the solution is to remove hook of it:
```sh
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
```
