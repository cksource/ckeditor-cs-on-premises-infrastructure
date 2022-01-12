# Example usage of Azure Terraform modules

This catalog contains example usage of Terraform modules prepared for
provisioning CKEditor Collaboration Server.

**Note**: Before starting you have to login into the Azure CLI tool. You can
download it here: https://docs.microsoft.com/en-us/cli/azure/

## Quickstart
The project requires resource group `cksource` and storage account in that
resource group named the same - `cksource`. You can change used resource group
and storage group inside [infrastructure/main.tf](./infrastructure/main.tf) file
and [service/main.tf](./service/main.tf)

The first step is to provide the infrastructure needed to run the service. The
the process can take a long duration of time, usually around 30 minutes.

```bash
cd infrastructure

# Initialize the terraform project
terraform init

# Verify resources planned to create and apply their creation
terraform apply
```

After the creation of the infrastructure, it is time to apply the service
module.

**Note**: While running the `apply` command you will be required to pass your
`docker_token`, `license_key` and `environments_management_secret_key` Where to
find your credentials:
- The `license_key` can be found in [CKEditor Ecosystem
  Dashboard](https://dashboard.ckeditor.com/) in your CKEditor Collaboration
  Server On-Premises subscription page.
- The `docker_token` can be found in CKEditor Ecosystem Dashboard in your
  CKEditor Collaboration Server On-Premises subscription page in the *Download
  token* section. If you do not see any tokens, you can create them with the
  *Create new token* button.
- The `environments_management_secret_key` is your password, that will be used
  to access the Collaboration Server On-Premises [management
  panel](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/management.html)


**Note 2**: You can omit using terraform module to provision the CKEditor
Collaboration Server by using Helm directly. Check our Helm charts directory for
more information: [Helm](/kubernetes/helm/)

```bash
cd service

# Initialize the terraform project
terraform init

# Verify resources planned to create and apply their creation
terraform apply
```

The CKEditor Collaboration Server should be accessible under the IP address
assigned to created Application Gateway. You can find the IP of the gateway in
the Azure panel or by Azure CLI.

You can validate the deployment of the CKEditor Collaboration Server by
accessing the management panel under the `/panel` path. So, it will be
`http://${APPLICATION_GATEWAY_FRONTEND_IP}/panel`.
