# Example usage of Azure Terraform modules

This catalog contains examples of how the Terraform modules can be used for
provisioning Collaboration Server On-Premises.

**Note**: Before starting, you have to log into the Azure CLI tool. You can
download it here: https://docs.microsoft.com/en-us/cli/azure/

## Quickstart
The project requires a resource group called `ckeditor-cs` and a storage account
in that resource group named the same - `ckeditor-cs`. You can change the used
resource group and the storage group in
[infrastructure/main.tf](./infrastructure/main.tf) and
[service/main.tf](./service/main.tf)

The first step is to provide the infrastructure needed to run the service. The
the process can take a long time, usually around 30 minutes.

**Note**: While running the `apply` command, you will be required to pass your
`ssh_public_key_path`. The content of the file under the path will be used as
an authorized SSH key to connect to the nodes in the Kubernetes cluster.


```bash
cd infrastructure

# Initialize the terraform project
terraform init

# Verify the resources planned to be created and apply their creation
terraform apply
```

After the creation of the infrastructure, it is time to apply the service
module.

**Note**: While running the `apply` command, you will be required to pass your
`docker_token`, `license_key` and `environments_management_secret_key`. Here is
where to find your credentials:
- `license_key` can be found in the [CKEditor Ecosystem
  Dashboard](https://dashboard.ckeditor.com/) on your CKEditor Collaboration
  Server On-Premises subscription page.
- `docker_token` can be found in the [CKEditor Ecosystem
  Dashboard](https://dashboard.ckeditor.com/) on your CKEditor Collaboration
  Server On-Premises subscription page in the *Download token* section. If you
  do not see any tokens, you can create them with the *Create new token* button.
- `environments_management_secret_key` is your password used to access the
  Collaboration Server On-Premises [Management
  Panel](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/management.html)


**Note 2**: You can omit using Terraform modules to provision Collaboration
Server On-Premises by using Helm directly. Check our Helm charts directory for
more information: [Helm](/kubernetes/helm/)

```bash
cd service

# Initialize the terraform project
terraform init

# Verify resources planned to create and apply their creation
terraform apply
```

Collaboration Server On-Premises should be accessible under the IP address
assigned to the created Application Gateway. You can find the IP of the gateway
in the Azure panel or via the Azure CLI.

You can validate the deployment of the Collaboration Server On-Premises by
accessing the management panel under the `/panel` path, i.e.
`http://${APPLICATION_GATEWAY_FRONTEND_IP}/panel`.
