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

variable "location" {
  description = "Azure region. Check VM size availability before applying."
  type        = string
  default     = "eastus"
}

variable "name" {
  description = "Short name used for this lesson's resources."
  type        = string
  default     = "tf-day5"
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
variable "ssh_source_cidr" {
  description = "Your public IPv4 address with /32; restricts SSH and the practice app."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.ssh_source_cidr)) && endswith(var.ssh_source_cidr, "/32")
    error_message = "Supply your public IPv4 address with /32."
  }
}

variable "ssh_private_key_path" {
  description = "Local private key path. Never commit the private key."
  type        = string
  default     = "~/.ssh/terraform_azure"
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

resource "azurerm_public_ip" "lesson" {
  name                = "${var.name}-ip"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "lesson" {
  name                = "${var.name}-nsg"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  security_rule {
    name                       = "AllowSSHAndAppFromYou"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "8080"]
    source_address_prefix      = var.ssh_source_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "lesson" {
  network_interface_id      = azurerm_network_interface.lesson.id
  network_security_group_id = azurerm_network_security_group.lesson.id
}
resource "azurerm_network_interface" "lesson" {
  name                = "${var.name}-nic"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lesson.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lesson.id
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

# Keep shell work separate from the VM resource. Retry with -replace if needed.
resource "terraform_data" "configure" {
  triggers_replace = [azurerm_linux_virtual_machine.lesson.id, filesha256("${path.module}/app.py")]
  provisioner "file" {
    source      = "${path.module}/app.py"
    destination = "/home/azureuser/app.py"
    connection {
      type        = "ssh"
      user        = "azureuser"
      host        = azurerm_public_ip.lesson.ip_address
      private_key = file(pathexpand(var.ssh_private_key_path))
      timeout     = "10m"
    }
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "azureuser"
      host        = azurerm_public_ip.lesson.ip_address
      private_key = file(pathexpand(var.ssh_private_key_path))
      timeout     = "10m"
    }
    inline = [
      "sudo cloud-init status --wait",
      "sudo apt-get -o Acquire::Retries=5 update",
      "sudo env DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=5 install -y python3-flask",
      "sudo systemctl stop terraform-demo.service || true",
      "sudo systemctl reset-failed terraform-demo.service || true",
      "sudo systemd-run --unit=terraform-demo --property=User=azureuser /usr/bin/python3 /home/azureuser/app.py",
    ]
  }
  provisioner "local-exec" {
    command = "echo Azure practice app is ready"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "echo Removing the provisioner practice record"
  }
  depends_on = [azurerm_network_interface_security_group_association.lesson]
}

output "website_url" {
  value = "http://${azurerm_public_ip.lesson.ip_address}:8080"
}

# Finish this example with: terraform destroy
