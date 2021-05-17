# CKEditor Collaboration Server On-Premises Helm charts

Use this Helm charts to provision CKEditor Collaboration Server on your
Kubernetes cluster.

**Note**: This script uses Helm. If you haven't worked with it before, we highly
recommend to get familiar with it first: https://helm.sh/docs/intro/quickstart/

## List of charts

Short description of every helm chart in this directory:

### [ckeditor-cs](ckeditor-cs)

Helm chart containing the resources to run CKEditor Collaboration Server
configured to connect to external third-party services.

### [ckeditor-cs-development-stack](ckeditor-cs-development-stack)

Fast way to provision whole infrastructure needed for CKEditor Collaboration
Server. Used charts as a dependencies:
- `ckeditor-cs`
- `bitnami/mysql`
- `bitnami/redis`

>:warning: **Not for production purposes!** This configuration is insecure, not
>persistent and its purpose is testing only.

## Quick start

- create imagePullSecret for pulling images from CKEditor container registry,
  replace `xxx` with authentication token
```sh
kubectl create secret docker-registry docker-cke-cs-com \
    --docker-username "cs" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="xxx"
```

- install chart in cluster
```sh
helm install ckeditor-cs ./ckeditor-cs \
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

- test deployment
```sh
kubectl run ckeditor-cs-tests -i --rm \
    --image docker.cke-cs.com/cs-tests:"$(kubectl get deployments.apps ckeditor-cs-server -o json | jq -r '.spec.template.spec.containers[0].image' | sed 's/.*://')" \
    --env APPLICATION_ENDPOINT="$(kubectl get ingresses.networking.k8s.io ckeditor-cs-server -o json | jq -r '.spec.rules[0].host' | sed 's|^|http://|')" \
    --env ENVIRONMENTS_MANAGEMENT_SECRET_KEY="$(kubectl get secret ckeditor-cs-server -o json | jq -r '.data.ENVIRONMENTS_MANAGEMENT_SECRET_KEY' | base64 -d)" \
    --overrides='{ "spec": { "imagePullSecrets": [{"name": "docker-cke-cs-com"}] } }' \
    --restart='Never'
```

## Configuration

Easier configuration management can be achieved by creating separate based on
`ckeditor-cs/values.yaml` configuration file. It can be passed to `helm install`
by `-f [path]` flag.

> :warning: **If you want to store configuration**: Make sure your environment
> variables are secure before saving them in external service. You can use
> [SOPS](https://github.com/mozilla/sops) for encrypting specific parts of yaml
> file.

Environment variables mentioned in configuration file are an absolute minimum to
run the service. Visit documentation for whole list of configuration options:

https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/installation/docker.html#docker-container-environment-variables

## Infrastructure overview

![CKEditor-cs helm chart diagram](diagram.jpg)

### Pod

Individual instance of the CKEditor Collaboration Server container.

### Deployment

Manages provisioning pods, handles creating, replacing and scaling pods.

### Service

Abstract object that exposes a specific set of pods as a network interface. That
set if pods targeting is determined by selectors assigned to them.

### Ingress

Ingress manages external access to the service located in cluster. Creates
routing by hostnames and can handle terminating SSL/TLS.

### ServiceAccount

Automatically enabled authenticator in Kubernetes. Uses signed bearer tokens to
verify requests. Bearer tokens are mounted into pods.

### Secret

Storage and management of sensitive information. In this use case, environment
variables passed to the pods.

## Destroy installed chart
You can clean remove installed deployment from Kubernetes by running `helm
delete ckeditor-cs` command.
