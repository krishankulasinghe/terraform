# Conditional Expressions

Conditional expressions in Terraform are used to define conditional logic within your configurations. They allow you to make decisions or set values based on conditions. Conditional expressions are typically used to control whether resources are created or configured based on the evaluation of a condition.

The syntax for a conditional expression in Terraform is:

```hcl
condition ? true_val : false_val
```

- `condition` is an expression that evaluates to either `true` or `false`.
- `true_val` is the value that is returned if the condition is `true`.
- `false_val` is the value that is returned if the condition is `false`.

Both values must have compatible types. Here are some common use cases and examples of how to use conditional expressions in Terraform.

## Conditional Resource Creation Example

Save this complete example as `main.tf` in a new practice folder after Day 1 Azure login. It creates only Resource Groups, with no separate resource charge:

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

variable "create_extra_group" {
  type    = bool
  default = false
}

resource "azurerm_resource_group" "lesson" {
  name     = "tf-condition-rg"
  location = "eastus"
}

resource "azurerm_resource_group" "extra" {
  count    = var.create_extra_group ? 1 : 0
  name     = "tf-condition-extra-rg"
  location = "eastus"
}

output "extra_group_name" {
  value = try(azurerm_resource_group.extra[0].name, "not created")
}
```

If `create_extra_group` is true, `count` creates one extra group. If false, it creates none. Count resources use indexed addresses such as `extra[0]`. `try` supplies a fallback when no first item exists. Switching from true to false after creation plans deletion; review it.

# Conditional Variable Assignment Example

Add this fragment to the same example:

```hcl
variable "environment" {
  description = "Environment type"
  type        = string
  default     = "development"
}

variable "production_subnet_cidr" {
  description = "CIDR block for production subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "development_subnet_cidr" {
  description = "CIDR block for development subnet"
  type        = string
  default     = "10.0.2.0/24"
}

locals {
  subnet_cidr = var.environment == "production" ? var.production_subnet_cidr : var.development_subnet_cidr
}

output "selected_subnet_cidr" {
  value = local.subnet_cidr
}
```

The `locals` block assigns `subnet_cidr` based on `environment`. Production uses `production_subnet_cidr`; otherwise it uses `development_subnet_cidr`. This demonstrates selection without creating a subnet.

## Conditional Resource Configuration

Add this fragment to the same example. It creates an Azure Network Security Group with a practice SSH rule. There is no VM or NIC attached, so it does not open access to a computer:

```hcl
variable "enable_ssh" {
  type    = bool
  default = false
}

variable "ssh_source_cidr" {
  description = "Your public IPv4 address with /32."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.ssh_source_cidr)) && endswith(var.ssh_source_cidr, "/32")
    error_message = "Use your public IPv4 address with /32."
  }
}

resource "azurerm_network_security_group" "lesson" {
  name                = "conditional-nsg"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  security_rule {
    name                       = "PracticeSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = var.enable_ssh ? "Allow" : "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_cidr
    destination_address_prefix = "*"
  }
}
```

If `enable_ssh` is true, this rule allows SSH from your one public IPv4 address; otherwise it denies that traffic. `/32` means one IPv4 address. An NSG also has default rules; this one rule does not replace them. Do not use `0.0.0.0/0` to allow SSH from the whole internet.

Conditional expressions in Terraform provide a powerful way to make decisions and customize your infrastructure deployments based on various conditions and variables. They enhance the flexibility and reusability of your Terraform configurations.

## Practice and cleanup

Terraform will ask for `ssh_source_cidr` if you added the last fragment. Supply your public IPv4 address with `/32` and keep the value for cleanup. Initialize, check and review before applying:

```shell
terraform init
terraform fmt
terraform validate
terraform plan -out=condition.tfplan
terraform apply condition.tfplan
terraform output
terraform destroy
```

Try a new plan with `-var='create_extra_group=true'`, then with `-var='environment=production'`, and inspect the difference. To deploy a chosen variation, save and apply that plan. Destroy with the same inputs.

`for_each` is another way to repeat resources. It creates one resource for each named map or set item. The web project uses keys `one` and `two`, producing addresses such as `web["one"]`. Use stable keys known before apply. Removing one key deletes that item without renumbering others. Do not use `count` and `for_each` on the same resource.
