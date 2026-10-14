# Multiple Providers

Use more than one provider when a project needs more than one API. Here `random` creates a name suffix locally, and `azurerm` creates the Azure Resource Group. Neither provider needs a hard-coded secret. The random suffix is stored in state and reused; it does not change every apply.

Save this complete example in its own folder as `main.tf`. Complete Day 1 login first. This Resource Group has no separate resource charge.

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
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

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "example" {
  name     = "tf-multiple-${random_string.suffix.result}-rg"
  location = "eastus"
}
```

The reference to the suffix gives Terraform the creation order automatically. Providers are not resources, and using two providers does not require two clouds.

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=lesson.tfplan
terraform apply lesson.tfplan
terraform destroy
```
