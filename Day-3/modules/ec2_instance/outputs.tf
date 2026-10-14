output "private_ip" {
  value = azurerm_network_interface.lesson.private_ip_address
}

output "resource_group_name" {
  value = azurerm_resource_group.lesson.name
}

# Child modules are created and destroyed through their root module.
# From Day-3, finish with: terraform destroy
