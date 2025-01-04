# Output the resource group names and their locations

output "resource_groups_info" {
  value = {
    "compute_rg"   = {
      "name"     = azurerm_resource_group.compute_rg.name
      "location" = azurerm_resource_group.compute_rg.location
    },
    "network_rg"   = {
      "name"     = azurerm_resource_group.network_rg.name
      "location" = azurerm_resource_group.network_rg.location
    },
    "security_rg"  = {
      "name"     = azurerm_resource_group.security_rg.name
      "location" = azurerm_resource_group.security_rg.location
    },
    "monitoring_rg" = {
      "name"     = azurerm_resource_group.monitoring_rg.name
      "location" = azurerm_resource_group.monitoring_rg.location
    },
    "shared_services_rg" = {
      "name"     = azurerm_resource_group.shared_rg.name
      "location" = azurerm_resource_group.shared_rg.location
    }
  }
}

output "all_resource_group_ids" {
  description = "Resource Group IDs for all the resource groups"
  value = [
    azurerm_resource_group.compute_rg.id,
    azurerm_resource_group.network_rg.id,
    azurerm_resource_group.security_rg.id,
    azurerm_resource_group.monitoring_rg.id,
    azurerm_resource_group.shared_rg.id
  ]
}
