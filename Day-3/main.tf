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

module "linux_vm" {
  source               = "./modules/ec2_instance"
  name                 = "tf-day3"
  location             = "eastus"
  vm_size              = "Standard_B1s"
  admin_ssh_public_key = var.admin_ssh_public_key
}

output "private_ip" {
  value = module.linux_vm.private_ip
}

# Finish this example with: terraform destroy
