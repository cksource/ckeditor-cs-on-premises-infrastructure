# CKEditor AI Service On-Premises development stack Helm chart

>:warning: **Not for production purposes!** This configuration is insecure, not
>persistent and its purpose is testing only.

Helm chart for fast deployment of CKEditor AI Service On-Premises in Kubernetes
with a MySQL database and Redis. The AI service runs in its **standalone** variant and
stores uploaded files in the SQL database (`STORAGE_DRIVER=database`), so no
object storage is needed.

## Minimum requirements
- 4 CPU Core
- 4096MB RAM
- Kubernetes 1.19+
- Helm v3
- An API key for at least one LLM provider

## Quick start

### External Kubernetes cluster
Create imagePullSecret for pulling images from CKEditor container registry,
replace `xxx` with the download token from the
[CKEditor Customer Portal](https://portal.ckeditor.com/)
```sh
kubectl create secret docker-registry docker-cke-cs-com \
    --docker-username "ai-service" \
    --docker-server "https://docker.cke-cs.com" \
    --docker-password="xxx"
```

`PROVIDERS` is a stringified JSON object, so it is easiest to pass it through a
values file rather than `--set`. Create `dev.values.yaml` (git-ignored) and
replace `xxx` with a valid license key and provider API key:
```yaml
ai-service:
  secret:
    data:
      LICENSE_KEY: 'xxx'
      PROVIDERS: '{"openai":{"type":"openai","apiKeys":["xxx"]}}'
```

Installing helm chart in cluster:
```sh
cd ai-service-development-stack
helm repo update
helm dependency update
helm install ai-service . --values dev.values.yaml
```

> :warning: The release has to be named `ai-service`. The database and
> Redis hostnames in `values.yaml` are derived from that release name.

### Local environment

For the local minikube environment there is an `init.sh` script located in the
helm chart directory. The script was made with MacOS in mind and provisions the
minikube environment.

Run the `init.sh` script for minikube configuration provisioning. Replace `xxx`
with correct values.
```sh
LICENSE_KEY=xxx DOCKER_TOKEN=xxx \
  PROVIDERS='{"openai":{"type":"openai","apiKeys":["xxx"]}}' ./init.sh
```
The script waits until deployment is successful for 10 minutes. If you want to
check the status of the deployment you can either run `kubectl get pods` command
or access Kubernetes Dashboard by `minikube dashboard`.

By default the development environment can be accessed at
http://ai-service.organization.test — sign in to the management panel with the
`ENVIRONMENTS_MANAGEMENT_SECRET_KEY` from `values.yaml` (`secret`) to create an
environment and an access key.

## Deleting installation

```sh
helm delete ai-service
```

## Common issues

1. The first start can result in a few CrashLoopBackOff errors in the AI
   service container, it's normal and the cause is in MySQL startup time.
   However, it should be running correctly after a short time.

2. It is possible to encounter problems with Nginx ingress validation in
   minikube environment, the solution is to remove the hook of it:
```sh
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
```

3. If the service exits during start-up with a configuration error, check that
   `PROVIDERS` is a valid stringified JSON object and that at least one model
   is available for the `conversations`, `reviews` and `actions` features. See
   [LLM Providers](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/configuration.html#llm-providers).
