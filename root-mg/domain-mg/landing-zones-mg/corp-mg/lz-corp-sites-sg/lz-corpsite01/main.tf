provider "azurerm" {
  features {}
}

# Compute Resource Group
resource "azurerm_resource_group" "compute_rg"  {
  name     = "${var.prefix}-compute-${var.postfix}"
  location = var.location #Var.location["secondary"]
  tags     = var.tags
}
module "vm_deployment" {
  source  = "./rg-pool(modules)/compute-rg"
  vm_info = var.vm_info  # Pass the variable to the module
  location = var.location
  resource_group_name = var.resource_group_name.compute_rg.name
}

## Add in secondary location when ready for resiliency

# Network Resource Group
resource "azurerm_resource_group" "network_rg" {
  name     = "${var.prefix}-network-${var.postfix}"
  location = var.location
  tags     = var.tags
}

# Security Resource Group
resource "azurerm_resource_group" "security_rg" {
  name     = "${var.prefix}-security-${var.postfix}"
  location = var.location
  tags     = var.tags
}

# Monitoring Resource Group
resource "azurerm_resource_group" "monitoring_rg" {
  name     = "${var.prefix}-monitoring-${var.postfix}"
  location = var.location
  tags     = var.tags
}

# Identity Resource Group
resource "azurerm_resource_group" "identity_rg" {
    name = "${var.prefix}-identity-${var.postfix}"
}
# Miscellaneous (e.g., Shared Services) Resource Group
resource "azurerm_resource_group" "shared_rg" {
  name     = "${var.prefix}-shared-services${var.postfix}"
  location = var.location
  tags     = var.tags
}

module "hub_network" {
  source                 = "./lz-corpsite01-rg-pool(modules)/lz-corpsite01-network-rg"
  vnet_address_space     = var.vnet_address_spaces["hub_vnet"]
  subnet_address_spaces  = var.subnet_address_spaces["hub_vnet"]
}

module "spoke_network" {
  source                 = "./lz-corpsite01-rg-pool(modules)/lz-corpsite01-network-rg"
  vnet_address_space     = var.vnet_address_spaces["spoke_vnet"]
  subnet_address_spaces  = var.subnet_address_spaces["spoke_vnet"]
}
