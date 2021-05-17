# CKEditor Collaboration Server On-Premises development stack Helm chart

>:warning: **Not for production purposes!** This configuration is insecure, not persistent and its purpose is testing only.

Helm chart for fast deployment of Collaboration Server On-Premises in Kubernetes with MySQL database and Redis cluster.

## Minimum requirements
- 4 CPU Core
- 4096MB RAM
- Kubernetes 1.19+
- Helm v3

## Quick start

Create imagePullSecret for pulling images from CKEditor container registry, replace `xxx` with authentication token
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

For local minikube environment there is a `init.sh` script located in helm chart directory. The script was made with MacOS in mind and provisions minikube environment. Quick start:

Run `init.sh` script for minikube configuration provisioning.
```
./init.sh
```

Create `dev.values.yaml` file with license key:
```yaml
ckeditor-cs:
  server:
    secret:
      data:
        LICENSE_KEY: xxx
```

Next steps are the same as in [quick start](#quick-start) except in `helm install` command where additional flag has to be provided `-f dev.values.yaml`
