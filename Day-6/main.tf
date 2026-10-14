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

variable "admin_ssh_public_key" {
  description = "SSH public key text. See Day-1 setup."
  type        = string
}

variable "location" {
  description = "Azure region for all workspaces in this lesson."
  type        = string
  default     = "eastus"
}

variable "vm_sizes" {
  description = "All environments use the same small size to limit tutorial costs."
  type        = map(string)
  default = {
    dev   = "Standard_B1s"
    stage = "Standard_B1s"
    prod  = "Standard_B1s"
  }
}

module "linux_vm" {
  source               = "./modules/ec2_instance"
  name                 = "tf-day6-${terraform.workspace}"
  location             = var.location
  vm_size              = lookup(var.vm_sizes, terraform.workspace, "Standard_B1s")
  admin_ssh_public_key = var.admin_ssh_public_key
}

output "private_ip" {
  value = module.linux_vm.private_ip
}

# Destroy EACH workspace before deleting it: terraform destroy
