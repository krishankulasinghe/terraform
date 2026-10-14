terraform {
  required_version = ">= 1.11, < 2.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.12, < 6.0"
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

# VAULT_ADDR and VAULT_TOKEN come from your environment, never from this file.
provider "vault" {
  skip_child_token = true
}

ephemeral "vault_kv_secret_v2" "demo" {
  mount = "secret"
  name  = "tutorial"
}

# Temporary secret values can be used in provisioners without saving them in state.
resource "terraform_data" "secret_demo" {
  provisioner "local-exec" {
    command = "echo Vault practice secret is available to this command"
    environment = {
      PRACTICE_MESSAGE = ephemeral.vault_kv_secret_v2.demo.data["message"]
    }
  }
}

variable "location" {
  description = "Azure region. Check VM size availability before applying."
  type        = string
  default     = "eastus"
}

variable "name" {
  description = "Short name used for this lesson's resources."
  type        = string
  default     = "tf-day7"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,19}$", var.name))
    error_message = "Use 3-20 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "vm_size" {
  description = "Small paid VM size; availability and price depend on your subscription."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_ssh_public_key" {
  description = "Your SSH PUBLIC key text, supplied through TF_VAR_admin_ssh_public_key."
  type        = string
  validation {
    condition     = startswith(trimspace(var.admin_ssh_public_key), "ssh-rsa ")
    error_message = "Supply an RSA SSH public key, not a private key or file path."
  }
}

resource "azurerm_resource_group" "lesson" {
  name     = "${var.name}-rg"
  location = var.location
  tags     = { purpose = "terraform-tutorial" }
}

resource "azurerm_virtual_network" "lesson" {
  name                = "${var.name}-vnet"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "lesson" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.lesson.name
  virtual_network_name = azurerm_virtual_network.lesson.name
  address_prefixes     = ["10.10.1.0/24"]
}

# No public IP: this first VM has no internet-facing login endpoint.
resource "azurerm_network_interface" "lesson" {
  name                = "${var.name}-nic"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lesson.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "lesson" {
  name                            = "${var.name}-vm"
  location                        = azurerm_resource_group.lesson.location
  resource_group_name             = azurerm_resource_group.lesson.name
  size                            = var.vm_size
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.lesson.id]
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.admin_ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  tags = { purpose = "terraform-tutorial" }
}

output "private_ip" {
  description = "An internal address; it is not reachable directly from your laptop."
  value       = azurerm_network_interface.lesson.private_ip_address
}

output "resource_group_name" {
  value = azurerm_resource_group.lesson.name
}

# Finish this example with: terraform destroy
