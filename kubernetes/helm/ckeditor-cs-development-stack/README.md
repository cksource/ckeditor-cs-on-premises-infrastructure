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

### External Kubernetes cluster
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

### Local environment

For the local minikube environment there is a `init.sh` script located in helm
chart directory. The script was made with MacOS in mind and provisions minikube
environment.

Run `init.sh` script for minikube configuration provisioning. Replace `xxx` with
correct values.
```
LICENSE_KEY=xxx DOCKER_TOKEN=xxx ./init.sh
```
The script waits until deployment is successful for 5 minutes. If you want to
check the status of the deployment you can either run `kubectl get pods` command
or access Kubernetes Dashboard by `minikube dashboard`.

By default development environment can be accessed by
http://ckeditor-cs.organization.test address.

## Validating installation

The deployment configuration can be validated by running e2e tests.
```sh
./../test-deployment.sh
```

## Deleting installation

```sh
helm delete ckeditor-cs
```

## Common issues

1. The first start can result in a few CrashLoopBackOff errors in the server
   container, it's normal and the cause is in MySQL startup time. However, it
   should be running correctly after a short time.

2. It is possible to encounter problems with Nginx ingress validation in
   minikube environment, the solution is to remove the hook of it:
```sh
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
```
