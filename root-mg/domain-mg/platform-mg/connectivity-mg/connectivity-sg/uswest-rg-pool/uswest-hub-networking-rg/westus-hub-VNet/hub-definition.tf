provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  regions = {
    primary   = "West US" #syntax check
    secondary = "Central US"
  }
}
# Abstract into creating pre-defined resource groups per region to track states better.
resource "azurerm_resource_group" "hub_rg" {
  for_each = local.regions

  location = each.value
  name     = "${each.value}-hub-rg-${random_pet.rand.id}"
}
resource "random_pet" "rand" {}

module "hub_mesh" {
  source = "./.." # Change source to AVM repo or keep it local.
  hub_virtual_networks = {
    primary = {
      name                            = "westus-hub-vnet"
      address_space                   = ["10.77.0.0/22"]
      location                        = local.regions.primary #redo in var file
      resource_group_name             = azurerm_resource_group.hub_rg["primary"].name #redo in var file
      route_table_name_firewall       = "westus-hub-rt-primary" #need to add route_table_name_firewall or keep variable as is?
#     ddos_protection_plan_id         = "" # string
      dns_servers                     = ["10.100.0.1", "10.100.0.2"] # E.g: ["1.1.1.1", "8.8.8.8"]
#     flow_timeout_in_minutes         = "4" # Default is 4
      mesh_peering_enabled            = true  # 
#     resource_group_creation_enabled = false # default is true
      resource_group_lock_enabled     = false
#     resource_group_lock_name        = "" # string
#     resource_group_tags             = optional(map(string))
      routing_address_space           = ["10.77.0.0/16"]
#     hub_router_ip_address           = "" # string
#     tags = {                        = # ??optional(map(string), {})      

# Not sure if I apply these directly to the FW Route Table or a "user" route table      
     route_table_entries_firewall = {
        name                          = "internet-route" #string
        address_prefix                = "0.0.0.0/0" #string
        next_hop_type                 = "VirtualAplliance" #string
    
#        has_bgp_override              = false # optional(bool, false)
        next_hop_ip_address           = "10.77.0.4"    # optional(string)
      },
      {
        name                          = "westus-hub-to-corpsite01-spoke" #string
        address_prefix                = "192.168.7.0/24" #string
        next_hop_type                 = "VirtualAppliance" # not VirtualNetwork?
    
        has_bgp_override              = false # optional(bool, false)
        next_hop_ip_address           = "10.77.0.4"    # optional(string)
      },
      {
        name                          = "hub-vnet-route" #string
        address_prefix                = "10.77.0.0/22" #string
        next_hop_type                 = "VirtualNetwork" #string
    
        has_bgp_override              = false # optional(bool, false)
#        next_hop_ip_address           = ""    # optional(string)        
      }
    }
#    
#     user subnet routing tables get the same treatment
#     route_table_entries_user_subnets = {
#      {
#        name                          = "" #string
#        address_prefix                = "" #string
#        next_hop_type                 = "" #string
#    
#        has_bgp_override              = false # optional(bool, false)
#        next_hop_ip_address           = ""    # optional(string)
#      },
#    }

    subnets = {
      AzureFWSubnet = {
        name             = "AzureFierewallSubnet"
        address_prefixes = ["10.77.0.0/26"]
#        nat_gateway = {
#          id = ""
#        }
#        private_endpoint_network_policies_enabled = false # default is true
#        private_link_service_network_policies_enabled = false # default is true
#        route_table = {
#          id = "" # optional, string
#          assign_generated_route_table = false  # test to see if default is true
#        }
#        service_endpoints = "" # set, string
#        service_endpoint_policy_ids = "" # set, sring
#        delegations = {
#          name = "" # string
#          service_delegation = {
#            name = "" # string
#            actions = "" # list, string
#          }
        }
      AzureFWSubnet = {
        name             = "AzureFierewallManagementSubnet" # needed for premium AZFW sku
        address_prefixes = ["10.77.0.64/26"]
      }
    }
      firewall = {
        subnet_address_prefix = "10.77.0.0/26"
        name                  = "westus-pfw-hub-primary" #Must be named 'AzureFirewallSubnet'?
        sku_name              = "AZFW_Hub" #changed from AZFW_VNet
        sku_tier              = "Premium" #changed to premium
        zones                 = ["1", "2", "3"] #?
        default_ip_configuration = {
          public_ip_config = {
            name  = "westus-hub-primary-pip-pfw" #? Configure prior or in another module?
            sku_tier = "Regional" # 'Regional' or 'Global'
            zones = ["1", "2", "3"]
          }
        }
        firewall_policy = { #DNAT/SNAT rules?
          name = "fwp-hub-primary"  # configure separate module or add in here.
          sku = "Standard"
          dns = {
            proxy_enabled = true #?
            servers       = ["10.100.0.1", "10.100.0.2"]
          }
        }
      }
    }
  }
    secondary = { # Rename and ensure this is for resiliency not for a separate landing zone. 
                  # I'm configuring a separate landing zone for that. 
      name                            = "vnet-hub-secondary"
      address_space                   = ["10.1.0.0/22"]
      location                        = local.regions.secondary
      resource_group_name             = azurerm_resource_group.hub_rg["secondary"].name
      resource_group_creation_enabled = false
      resource_group_lock_enabled     = false
      mesh_peering_enabled            = true
      route_table_name                = "rt-hub-secondary"
      routing_address_space           = ["10.1.0.0/16"]
      firewall = {
        subnet_address_prefix = "10.1.0.0/26"
        name                  = "fw-hub-secondary"
        sku_name              = "AZFW_Hub" #changed from AZFW_VNet
        sku_tier              = "Standard"
        zones                 = ["1", "2", "3"]
        default_ip_configuration = {
          public_ip_config = {
            name  = "pip-pfw-hub-secondary"
            zones = ["1", "2", "3"]
          }
        }
        firewall_policy = {
          name = "fwp-hub-secondary"
          dns = {
            proxy_enabled = true
          }
        }
      }
    }
  }
}
