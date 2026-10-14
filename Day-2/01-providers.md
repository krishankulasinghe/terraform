# Providers 

A provider in Terraform is a plugin that enables interaction with an API. 
This includes cloud providers, SaaS providers, and other APIs. The providers are specified in the Terraform configuration code. They tell Terraform which services it needs to interact with.

For example, to create an Azure Resource Group, use the AzureRM provider. A Resource Group alone has no separate charge. Complete Day 1 login and set ARM_SUBSCRIPTION_ID first. Save this standalone example in its own folder:

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

resource "azurerm_resource_group" "example" {
  name     = "tf-provider-demo-rg"
  location = "eastus"
}
```

When you run terraform init, Terraform installs AzureRM. Plan and apply use it to talk to Azure and manage the Resource Group.

Here are some other examples of providers:

- `azurerm` - for Azure
- `google` - for Google Cloud Platform
- `kubernetes` - for Kubernetes
- `openstack` - for OpenStack
- `vsphere` - for VMware vSphere

There are many other providers available, and new ones are being added all the time.

Providers are an essential part of Terraform. They allow Terraform to interact with a wide variety of cloud providers and other APIs. This makes Terraform a very versatile tool that can be used to manage a wide variety of infrastructure.


## Different ways to configure providers in terraform

Provider requirements and provider configuration have different jobs:

### In the root module

Configure the provider in the root module, as above. AzureRM requires `features {}`. Its subscription comes from `ARM_SUBSCRIPTION_ID`, and `use_cli = true` uses your Azure CLI login.

### In a child module

Reusable child modules declare their provider requirements and usually inherit the root's default configuration. Avoid putting a provider configuration in a reusable child. Day 3 shows this pattern. To pass a different configuration, use a `providers` map in the parent module call, for example:

```hcl
# Fragment: add to a module call after defining azurerm.secondary in the root.
providers = {
  azurerm = azurerm.secondary
}
```

### In the required_providers block

`required_providers` selects the plugin source and allowed versions; it does not configure login or region. The complete example above uses AzureRM 4.x. Commit the generated `.terraform.lock.hcl` file to record the selected version and checksums. Use `terraform init -upgrade` only for a deliberate update, then validate and review a new plan.

Run the standalone example and clean it up:

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=provider.tfplan
terraform apply provider.tfplan
terraform destroy
```
