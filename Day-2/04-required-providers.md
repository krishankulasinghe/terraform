# Provider Configuration

The required_providers block in Terraform is used to declare and specify the required providers for your Terraform module or configuration. It allows you to specify the provider name, source, and version constraints.

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli = true
}
```

The `provider` block configures AzureRM; the requirements block selects packages. Azure regions are set on resources using `location`.

`~> 4.0` allows AzureRM 4.x but excludes 5.0. `required_version` checks the Terraform CLI separately. Init records a selected provider version and checksums in `.terraform.lock.hcl`; commit it. Repeated init uses that version. For a deliberate update, run `terraform init -upgrade`, review the lock-file diff, validate and review a new plan. The lock file does not pin registry module versions; those use their own `version` argument.
