locals {
  servers = {
    one = "userdata.sh"
    two = "userdata1.sh"
  }
}

resource "azurerm_resource_group" "lesson" {
  name     = "tf-day2-web-rg"
  location = var.location
}

resource "azurerm_virtual_network" "lesson" {
  name                = "tutorial-vnet"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  address_space       = [var.cidr]
}

resource "azurerm_subnet" "web" {
  for_each             = local.servers
  name                 = "web-${each.key}"
  resource_group_name  = azurerm_resource_group.lesson.name
  virtual_network_name = azurerm_virtual_network.lesson.name
  address_prefixes     = [cidrsubnet(var.cidr, 8, each.key == "one" ? 0 : 1)]
}

resource "azurerm_network_security_group" "web" {
  name                = "web-nsg"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  security_rule {
    name                       = "AllowPracticeHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.http_source_cidr
    destination_address_prefix = "*"
  }
  # Azure's default AllowAzureLoadBalancerInBound rule permits health probes.
}

resource "azurerm_subnet_network_security_group_association" "web" {
  for_each                  = local.servers
  subnet_id                 = azurerm_subnet.web[each.key].id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_public_ip" "web" {
  name                = "web-lb-ip"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "web" {
  name                = "web-lb"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.web.id
  }
}

resource "azurerm_lb_backend_address_pool" "web" {
  name            = "web-servers"
  loadbalancer_id = azurerm_lb.web.id
}

resource "azurerm_lb_probe" "web" {
  name            = "http-health"
  loadbalancer_id = azurerm_lb.web.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

resource "azurerm_lb_rule" "web" {
  name                           = "http"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.web.id
  disable_outbound_snat          = true
}

# Explicit outbound access lets the private VMs install Apache.
resource "azurerm_lb_outbound_rule" "web" {
  name                    = "internet-outbound"
  loadbalancer_id         = azurerm_lb.web.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
  protocol                = "All"
  frontend_ip_configuration {
    name = "public"
  }
}

resource "azurerm_network_interface" "web" {
  for_each            = local.servers
  name                = "web-${each.key}-nic"
  location            = azurerm_resource_group.lesson.location
  resource_group_name = azurerm_resource_group.lesson.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web[each.key].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "web" {
  for_each                = local.servers
  network_interface_id    = azurerm_network_interface.web[each.key].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

resource "azurerm_linux_virtual_machine" "web" {
  for_each                        = local.servers
  name                            = "web-${each.key}"
  location                        = azurerm_resource_group.lesson.location
  resource_group_name             = azurerm_resource_group.lesson.name
  size                            = var.vm_size
  admin_username                  = "azureuser"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.web[each.key].id]
  custom_data                     = base64encode(file("${path.module}/${each.value}"))
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
  depends_on = [
    azurerm_lb_outbound_rule.web,
    azurerm_network_interface_backend_address_pool_association.web,
    azurerm_subnet_network_security_group_association.web,
  ]
}

resource "random_string" "suffix" {
  length  = 10
  special = false
  upper   = false
}

resource "azurerm_storage_account" "lesson" {
  name                            = "tflab${random_string.suffix.result}"
  location                        = azurerm_resource_group.lesson.location
  resource_group_name             = azurerm_resource_group.lesson.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "blob" {
  scope                = azurerm_storage_account.lesson.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_container" "lesson" {
  name                  = "practice"
  storage_account_id    = azurerm_storage_account.lesson.id
  container_access_type = "private"
  depends_on            = [azurerm_role_assignment.blob]
}

output "website_url" {
  value = "http://${azurerm_public_ip.web.ip_address}"
}

output "storage_account_name" {
  value = azurerm_storage_account.lesson.name
}

# Finish this paid two-VM example with: terraform destroy
