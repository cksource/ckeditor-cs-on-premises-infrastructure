# ArgoCD Configuration for CKEditor On-Premises

This directory contains ArgoCD configuration files for deploying CKEditor On-Premises applications using GitOps principles.

## Overview

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. This configuration demonstrates how to deploy CKEditor On-Premises applications using ArgoCD.

## Files

- `apps-ckbox.yaml`: Application definition for CKBox deployment (includes Helm values)
- `project.yaml`: ArgoCD project configuration (optional)

## Usage

### Prerequisites

- ArgoCD installed in your Kubernetes cluster
- Access to the CKEditor On-Premises infrastructure repository
- Kubernetes cluster with sufficient resources for the deployment
- kubectl configured with access to the target cluster
- argocd CLI installed (optional, for additional management features)

### Deployment

1. Apply the project configuration (optional):
   ```bash
   kubectl apply -f project.yaml
   ```

2. Apply the application configuration:
   ```bash
   kubectl apply -f apps-ckbox.yaml
   ```

### Configuration

- The `project.yaml` file defines an ArgoCD project with RBAC rules. You can use the default project instead.
- `apps-ckbox.yaml` defines how to deploy CKBox using Helm charts and includes the Helm values inline.

## Important Notes

1. **Project Configuration**:
   - The project name in `apps-ckbox.yaml` can be changed to `default` if not using custom projects
   - If using a custom project, ensure the project name matches the one in `project.yaml`
   - For production environments, consider restricting source repositories and destinations

2. **Helm Values**:
   - Helm values are defined inline in the application definition
   - To modify values, edit the `values` field in `apps-ckbox.yaml`
   - The values are defined using YAML block scalar notation (`|`)
   - Current configuration includes:
     - Replica count: 3
     - Readiness probe with health check endpoint
     - Automated sync and pruning

3. **Security Considerations**:
   - The project configuration uses permissive settings (`'*'`) for repositories and resources
   - For production environments, consider:
     - Restricting source repositories to specific Git repositories
     - Limiting destinations to specific namespaces and clusters
     - Restricting resource types that can be deployed
     - Implementing more granular RBAC policies

4. **Namespace**:
   - The example deploys to the `ckeditor` namespace
   - Make sure the namespace exists or has `CreateNamespace=true` in the sync policy
   - Consider using namespace-specific resource quotas and limits

## Documentation

For more information about ArgoCD configuration, refer to the [official documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/).

## Troubleshooting

If you encounter issues:

1. **Check Application Status**:
   ```bash
   argocd app get ckbox
   ```

2. **View Application Events**:
   ```bash
   kubectl get events -n argocd --field-selector involvedObject.name=ckbox
   ```

3. **Check ArgoCD Controller Logs**:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
   ```

4. **Manual Sync**:
   ```bash
   argocd app sync ckbox
   ```

5. **Common Issues**:
   - If sync fails, check the application events for specific error messages
   - Verify that the Helm chart path and values are correct
   - Ensure the target namespace exists or `CreateNamespace=true` is set
   - Check RBAC permissions if access is denied

