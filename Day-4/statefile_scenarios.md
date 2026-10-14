**Terraform State File**

Terraform is an Infrastructure as Code (IaC) tool used to define and provision infrastructure resources. The Terraform state file is a crucial component of Terraform that helps it keep track of the resources it manages and their current state. This file, often named `terraform.tfstate`, is a JSON formatted file that contains important information about the infrastructure's current state, such as resource attributes, dependencies, and metadata.

**Advantages of Terraform State File:**

1. **Resource Tracking**: The state file keeps track of all the resources managed by Terraform, including their attributes and dependencies. This ensures that Terraform can accurately update or destroy resources when necessary.

2. **Concurrency Control**: A backend that supports locking locks state during writes, preventing concurrent Terraform runs from modifying the same state. This does not lock Azure resources against portal changes. This helps avoid conflicts and ensures data consistency.

3. **Plan Calculation**: Terraform uses the state file to calculate and display the difference between the desired configuration (defined in your Terraform code) and the current infrastructure state. This helps you understand what changes Terraform will make before applying them.

4. **Resource Metadata**: The state file stores metadata about each resource, such as unique identifiers, which is crucial for managing resources and understanding their relationships.

**Disadvantages of Storing Terraform State in Version Control Systems (VCS):**

1. **Security Risks**: Sensitive information, such as API keys or passwords, may be stored in the state file if it's committed to a VCS. This poses a security risk because VCS repositories are often shared among team members.

2. **Versioning Complexity**: Managing state files in VCS can lead to complex versioning issues, especially when multiple team members are working on the same infrastructure.

**Overcoming Disadvantages with Remote Backends (Azure Blob Storage):**

A remote backend stores state outside your local files and Git. Azure Blob Storage encrypts data at rest and the `azurerm` backend uses Blob leases for locking. No separate lock database is needed. The backend is part of Terraform CLI; the AzureRM provider creates resources. They have separate authentication settings.

## Create storage before initializing the backend

The backend storage must exist before `terraform init`. Create it separately so `terraform destroy` in this lesson cannot delete the storage that holds its state. Complete Day 1 login and set `ARM_SUBSCRIPTION_ID`. You need resource creation permission and permission to grant the Blob data role. Contributor alone cannot grant roles. Ask an administrator if your account cannot grant them.

Run the following in PowerShell. Replace the example storage name with your own globally unique name (3–24 lowercase letters or digits). Keep these names for cleanup:

```powershell
$stateGroup = "tf-state-rg"
$stateAccount = "tfstateYOURUNIQUESUFFIX"
# Replace the placeholder above with lowercase letters/digits before running.
az group create --name $stateGroup --location eastus
az storage account create --name $stateAccount --resource-group $stateGroup --location eastus --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false --allow-shared-key-access false
$stateScope = az storage account show --name $stateAccount --resource-group $stateGroup --query id --output tsv
$userObjectId = az ad signed-in-user show --query id --output tsv
az role assignment create --assignee-object-id $userObjectId --assignee-principal-type User --role "Storage Blob Data Contributor" --scope $stateScope
az storage container create --name tfstate --account-name $stateAccount --auth-mode login
az storage account blob-service-properties update --account-name $stateAccount --resource-group $stateGroup --enable-versioning true --enable-delete-retention true --delete-retention-days 7
```

The role may take several minutes to become effective. For a `403`, wait and rerun container creation. Do not enable storage keys to bypass the error. These commands assume a human Azure CLI user. An automation identity needs its own role assignment and should use managed identity or workload identity federation.

In Bash, assign variables without `$` on the left (`stateGroup="tf-state-rg"`), and use `$(az ... --query id --output tsv)` for command results. The Azure CLI commands and flags are the same.

## Configure Remote Backend in Terraform

`backend.tf` contains:

```hcl
terraform {
  backend "azurerm" {
    use_cli          = true
    use_azuread_auth = true
    container_name   = "tfstate"
    key              = "day4/terraform.tfstate"
  }
}
```

From `Day-4`, pass the remaining names as non-secret backend settings. In the same PowerShell terminal:

```powershell
terraform init -backend-config="resource_group_name=$stateGroup" -backend-config="storage_account_name=$stateAccount"
terraform fmt
terraform validate
terraform plan -out=state.tfplan
terraform apply state.tfplan
terraform state list
terraform destroy
```

Day 1's public-key input is still needed: `main.tf` creates one paid Azure VM and disk. Verify the state Blob appears in the private container. No storage access key or client secret belongs in backend code or command arguments. Backend blocks cannot use `var.*`, locals or resource references.

For existing local state, back it up securely and use `terraform init -migrate-state` with these backend settings to copy it into Blob Storage; review the prompt. Use `-reconfigure` when changing connection settings without migrating state. Do not casually migrate a state that manages unrelated resources. Do not apply with the wrong backend.

## State Locking with Azure Blob Leases

The backend automatically acquires a lease during operations that write state. If another run holds it, wait or use `terraform plan -lock-timeout=5m`. Do not use `-lock=false` to bypass a teammate's operation. Only use `terraform force-unlock LOCK_ID` after confirming the owner is no longer running and the lock is stale. Never edit state JSON by hand. `terraform state list` shows managed addresses; `terraform state show ADDRESS` inspects one and may reveal sensitive data.

## Collaborating with Git and .gitignore

Commit `.tf`, documentation, non-secret example tfvars and `.terraform.lock.hcl`. Review changes with `git diff` and use your team's branch and pull request workflow. The repository's `.gitignore` excludes provider downloads, state, plans, local tfvars, keys and local backend settings. It deliberately allows provider lock files.

```shell
git status
git diff
git switch -c azure-lesson
```

Shared code alone does not share state. Teammates also need the same backend configuration and appropriate scoped data access. Never commit state or plans, even if outputs are marked sensitive. If a secret was committed, remove it from history as appropriate and rotate the credential.

## Cleanup

First run `terraform destroy` from `Day-4` and confirm the VM Resource Group is gone. Keep state storage until all infrastructure using it has been destroyed. Blob versions and retention can continue to incur storage charges. For this dedicated, unshared practice backend only, after successful destroy, delete the separate storage Resource Group:

```powershell
az group delete --name $stateGroup
```

Review the confirmation before deleting it: this removes its storage and state history. For a shared backend, keep it and manage retention with your team.

References: [Azure backend authentication and locking](https://developer.hashicorp.com/terraform/language/backend/azurerm), [Azure CLI storage commands](https://learn.microsoft.com/en-us/cli/azure/storage).
