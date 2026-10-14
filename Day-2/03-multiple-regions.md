# Multiple Region Implementation in Terraform

In Azure, a region belongs to each resource's `location`, not to the provider. One provider can create resources in both East US and West Europe. A Resource Group's location stores group metadata; resources inside it may be in different regions if the Azure service permits that.

An **alias** is a second name for a provider configuration. It is useful for another subscription or different provider settings. This free Resource Group example uses the same signed-in subscription for both aliases so you can learn the syntax without a second account. Its second region is intentional for this lesson; other examples default to East US.

Save this complete code in a separate practice folder as `main.tf`, after Day 1 login:

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

provider "azurerm" {
  alias = "secondary"
  features {}
  use_cli = true
}

resource "azurerm_resource_group" "east" {
  name     = "tf-region-east-rg"
  location = "eastus"
}

resource "azurerm_resource_group" "west" {
  provider = azurerm.secondary
  name     = "tf-region-west-rg"
  location = "westeurope"
}
```

For another subscription, set the alias's `subscription_id` to an input variable containing that subscription's ID, and ensure your `az login` identity can access it. An ID is not a secret. Do not add client secrets.

When sending an alias to a child module, map the child's default `azurerm` to `azurerm.secondary` in the parent's `providers` argument. If the child itself refers to an alias, it must declare it in `configuration_aliases`.

Resource Groups have no separate resource charge. VMs in two regions would be two paid VMs and may need different available sizes. Run:

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=lesson.tfplan
terraform apply lesson.tfplan
terraform destroy
```
