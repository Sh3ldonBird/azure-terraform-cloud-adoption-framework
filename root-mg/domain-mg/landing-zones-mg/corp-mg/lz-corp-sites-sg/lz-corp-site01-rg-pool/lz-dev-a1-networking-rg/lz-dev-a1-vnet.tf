terraform {
  required_version = ">= 1.9.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.7.0, < 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false  #policy ?
    }
  }
}

locals {
  regions = {
    primary   = "westus"
    secondary = "centralus"
  }
}

resource "azurerm_resource_group" "hub_rg" {
  for_each = local.regions

  location = each.value
  name     = "rg-hub-${each.value}-${random_pet.rand.id}"
}

resource "random_pet" "rand" {}

# Reference uswest-dev-hub-vnet

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "private_key" {
  filename = "key.pem"
  content  = tls_private_key.key.private_key_pem
}

# Spoke 1
resource "azurerm_resource_group" "spoke1" {
  location = local.regions.primary
  name     = "rg-spoke1-${random_pet.rand.id}"
} # Fix this to use the lz-a1-networking-rg or similar

module "lz-dev-a1-spoke1-vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.7.1"

  name                = "vnet-spoke1-${random_pet.rand.id}"
  address_space       = ["10.0.4.0/24"]
  resource_group_name = azurerm_resource_group.spoke1.name
  location            = azurerm_resource_group.spoke1.location

  peerings = {
    "spoke1-peering" = {
      name                                 = "spoke1-peering"
      remote_virtual_network_resource_id   = module.hub_mesh.virtual_networks["primary"].id
      allow_forwarded_traffic              = true
      allow_gateway_transit                = false
      allow_virtual_network_access         = true
      use_remote_gateways                  = false
      create_reverse_peering               = true
      reverse_name                         = "spoke1-peering-back"
      reverse_allow_forwarded_traffic      = false
      reverse_allow_gateway_transit        = false
      reverse_allow_virtual_network_access = true
      reverse_use_remote_gateways          = false
    }
  }
  subnets = {
    spoke1-subnet = {
      name             = "spoke1-subnet"
      address_prefixes = ["10.0.4.0/28"]
    }
  }
}

# Spoke 2
# Make sure it's configured for resiliency
# DRP primarily

resource "azurerm_resource_group" "spoke2" {
  location = local.regions.secondary
  name     = "rg-spoke2-${random_pet.rand.id}"
}

module "spoke2_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.7.1"

  name                = "vnet-spoke2-${random_pet.rand.id}"
  address_space       = ["10.1.4.0/24"]
  resource_group_name = azurerm_resource_group.spoke2.name
  location            = azurerm_resource_group.spoke2.location

  peerings = {
    "spoke2-peering" = {
      name                                 = "spoke2-peering"
      remote_virtual_network_resource_id   = module.hub_mesh.virtual_networks["secondary"].id
      allow_forwarded_traffic              = true
      allow_gateway_transit                = false
      allow_virtual_network_access         = true
      use_remote_gateways                  = false
      create_reverse_peering               = true
      reverse_name                         = "spoke2-peering-back"
      reverse_allow_forwarded_traffic      = false
      reverse_allow_gateway_transit        = false
      reverse_allow_virtual_network_access = true
      reverse_use_remote_gateways          = false
    }
  }
  subnets = {
    spoke2-subnet = {
      name             = "spoke2-subnet"
      address_prefixes = ["10.1.4.0/28"]
    }
  }
}

