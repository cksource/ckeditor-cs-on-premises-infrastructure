# CKEditor Collaboration Server Helm Chart

This Helm chart deploys CKEditor Collaboration Server On-Premises installation on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Access to CKEditor Collaboration Server container registry

## GitOps Support

This chart is compatible with GitOps tools like ArgoCD. The following features are supported:

- Sync waves for proper resource ordering
- Prune and sync options for ArgoCD
- GitOps-friendly annotations and labels

### ArgoCD Integration

To deploy this chart using ArgoCD, create an Application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ckeditor-cs
  namespace: argocd
spec:
  project: default
  source:
    repoURL: <your-git-repo-url>
    targetRevision: HEAD
    path: kubernetes/helm/ckeditor-cs
  destination:
    server: https://kubernetes.default.svc
    namespace: ckeditor-cs
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - Prune=true
      - CreateNamespace=true
```

## Installing the Chart

To install the chart with the release name `ckeditor-cs`:

```bash
helm install ckeditor-cs . --namespace ckeditor-cs
```

## Uninstalling the Chart

To uninstall/delete the `ckeditor-cs` deployment:

```bash
helm uninstall ckeditor-cs --namespace ckeditor-cs
```

## Configuration

The following table lists the configurable parameters of the CKEditor Collaboration Server chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `server.replicaCount` | Number of server instances | `2` |
| `server.image.repository` | Server image repository | `docker.cke-cs.com/cs` |
| `server.image.tag` | Server image tag | `latest` |
| `worker.enabled` | Enable worker component | `false` |
| `worker.replicaCount` | Number of worker instances | `1` |
| `worker.image.repository` | Worker image repository | `docker.cke-cs.com/cs-worker` |
| `worker.image.tag` | Worker image tag | `latest` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```bash
helm install ckeditor-cs . --namespace ckeditor-cs \
  --set server.replicaCount=3 \
  --set worker.enabled=true
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example:

```bash
helm install ckeditor-cs . --namespace ckeditor-cs -f values.yaml
```

## GitOps Best Practices

1. Always use versioned tags for images instead of `latest`
2. Store sensitive values in a separate values file or use a secrets management solution
3. Use sync waves to ensure proper resource ordering
4. Enable pruning to maintain cluster state in sync with Git
5. Use proper labels and annotations for resource tracking

## Support

For support, please contact CKEditor support team.

## Minimum requirements
- 2 CPU Core
- 1024MB RAM
- One of the following SQL databases:
  - MySQL 5.6/5.7
  - PostgreSQL min. 12.0
- External Redis cluster 3.2.6 or newer
- Kubernetes 1.19+
- Helm v3

The default configuration of running this service requires the reservation of 2
CPU cores and 1GB of RAM in the cluster. For more information about resources
usage look here:
https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/requirements.html#docker

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
>:warning: By default, the chart installs the Ckeditor Collaboration Server
>on-premises with the "latest" tag. If you are using this chart for a production
>environment, it's strongly recommended to change the container image tag to a
>numeric representation of the version you want to install.
```sh

helm install ckeditor-cs ./ckeditor-cs \
    --set image.tag="latest" \
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

- validate installation by running tests
```sh
./../test-deployment.sh
```

## Deleting

```sh
helm delete ckeditor-cs
```
