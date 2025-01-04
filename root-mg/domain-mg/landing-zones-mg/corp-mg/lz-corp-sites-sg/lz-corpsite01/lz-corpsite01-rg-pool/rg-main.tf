provider "azurerm" {
  features {}
}

# Compute Resource Group
resource "azurerm_resource_group" "compute_rg"  {
  name     = "${var.prefix}-compute${var.postfix}"
  location = var.location #Var.location["secondary"]
  tags     = var.tags
}
## Add in secondary location when ready for resiliency

# Network Resource Group
resource "azurerm_resource_group" "network_rg" {
  name     = "${var.prefix}-network${var.postfix}"
  location = var.location
  tags     = var.tags
}

# Security Resource Group
resource "azurerm_resource_group" "security_rg" {
  name     = "${var.prefix}-security${var.postfix}"
  location = var.location
  tags     = var.tags
}

# Monitoring Resource Group
resource "azurerm_resource_group" "monitoring_rg" {
  name     = "${var.prefix}-monitoring${var.postfix}"
  location = var.location
  tags     = var.tags
}

# Miscellaneous (e.g., Shared Services) Resource Group
resource "azurerm_resource_group" "shared_rg" {
  name     = "${var.prefix}-shared-services${var.postfix}"
  location = var.location
  tags     = var.tags
}

##????
resource "azurerm_resource_group" "rg" {
  for_each = local.resource_groups

  location = each.value.location
  name     = each.value.name
  tags     = each.value.tags
}

resource "azurerm_management_lock" "rg_lock" {
  for_each = { for k, v in local.resource_groups : k => v if v.lock }

  lock_level = "CanNotDelete"
  name       = coalesce(each.value.lock_name, substr("lock-${each.value.name}", 0, 90))
  scope      = azurerm_resource_group.rg[each.key].id
}