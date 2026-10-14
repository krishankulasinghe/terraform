terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
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
