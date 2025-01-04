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

#locals {
#  regions = {
#    primary   = "westus"
#    secondary = "centralus"
#  }
#}

resource "azurerm_resource_group" "hub_rg" {
  for_each = local.regions

  location = each.value
  name     = "rg-hub-${each.value}-${random_pet.rand.id}"
}

resource "random_pet" "rand" {}

#resource "tls_private_key" "key" {
#  algorithm = "RSA"
#  rsa_bits  = 4096
#}
#
#resource "local_sensitive_file" "private_key" {
#  filename = "key.pem"
#  content  = tls_private_key.key.private_key_pem
#}


module "lz-corpsite01-rg-pool" {
  source = "../"
}
#Defining spoke VNet that will interface with the WestUS Hub VNet.
resource "azurerm_resource_group" "corp-sites-spoke01" {
  location = module.parent_resource_groups.resource_groups_info.network_rg.location
  name     = module.parent_resource_groups.resource_groups_info.network_rg.name
} 

module "lz-corpsite01-spoke-vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.7.1"

  name                = "lz-corpsite01-spoke-vnet" #"vnet-spoke1-${random_pet.rand.id}"
  address_space       = ["192.168.0.0/16"]
  resource_group_name = azurerm_resource_group.corp-sites-spoke01.name
  location            = azurerm_resource_group.corp-sites-spoke01.location

  # Eventually peer only specific subnets
  peerings = { 
    "WestUS-Hub-to-CorpSite01-spoke-peering" = {
      name                                 = "WestUS-Hub-to-CorpSite01-spoke-peering"
      remote_virtual_network_resource_id   = module.hub_mesh.virtual_networks["primary"].id
      allow_forwarded_traffic              = true
      allow_gateway_transit                = false
      allow_virtual_network_access         = true
      use_remote_gateways                  = false
      create_reverse_peering               = true
      reverse_name                         = "WestUS-Hub-to-CorpSite01-spoke-peering-back"
      reverse_allow_forwarded_traffic      = false
      reverse_allow_gateway_transit        = false
      reverse_allow_virtual_network_access = true
      reverse_use_remote_gateways          = false
    }
# Not sure if I apply these directly to the FW Route Table or a "user" route table      
    route_table_entries_firewall = {
      name                          = "default-to-firewall" #string
      address_prefix                = "0.0.0.0/0" #string
      next_hop_type                 = "VirtualAplliance" #string
  
#        has_bgp_override              = false # optional(bool, false)
      next_hop_ip_address           = "10.77.0.4"    # optional(string)
    },
    {
      name                          = "westus-hub-vnet" #string
      address_prefix                = "10.77.0.0/22" # narrow this down down the road #string
      next_hop_type                 = "VirtualNetwork"
  
      has_bgp_override              = false # optional(bool, false)
      next_hop_ip_address           = ""    # optional(string)
    }
  }
  # Additional named subnets incoming
  subnets = {
    spoke1-subnet = {
      name             = "lz-corpsite01-spoke-sn1"
      address_prefixes = ["192.168.7.0/24"]
    }
  }
}

# Spoke 2
# Configure for resiliency later

#resource "azurerm_resource_group" "spoke2" {
#  location = local.regions.secondary
#  name     = "rg-spoke2-${random_pet.rand.id}"
#}
#
#module "spoke2_vnet" {
#  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
#  version = "0.7.1"
#
#  name                = "vnet-spoke2-${random_pet.rand.id}"
#  address_space       = ["10.1.4.0/24"]
#  resource_group_name = azurerm_resource_group.spoke2.name
#  location            = azurerm_resource_group.spoke2.location
#
#  peerings = {
#    "spoke2-peering" = {
#      name                                 = "spoke2-peering"
#      remote_virtual_network_resource_id   = module.hub_mesh.virtual_networks["secondary"].id
#      allow_forwarded_traffic              = true
#      allow_gateway_transit                = false
#      allow_virtual_network_access         = true
#      use_remote_gateways                  = false
#      create_reverse_peering               = true
#      reverse_name                         = "spoke2-peering-back"
#      reverse_allow_forwarded_traffic      = false
#      reverse_allow_gateway_transit        = false
#      reverse_allow_virtual_network_access = true
#      reverse_use_remote_gateways          = false
#    }
#  }
#  subnets = {
#    spoke2-subnet = {
#      name             = "spoke2-subnet"
#      address_prefixes = ["10.1.4.0/28"]
#    }
#  }
#}

