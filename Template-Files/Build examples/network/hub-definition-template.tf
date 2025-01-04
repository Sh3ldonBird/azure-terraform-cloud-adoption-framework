# https://registry.terraform.io/modules/Azure/avm-ptn-hubnetworking/azurerm/latest
# https://github.com/Azure/terraform-azurerm-avm-ptn-hubnetworking

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
      location                        = local.regions.primary #redo variables
      resource_group_name             = azurerm_resource_group.hub_rg["primary"].name #redo in variables
#     route_table_name_firewall       = "" # string
#     route_table_name_user_subnets   = "" # string
#     bgp_community                   = "" # string
#     ddos_protection_plan_id         = "" # string
#     dns_servers                     = [""] # E.g: ["1.1.1.1", "8.8.8.8"]
#     flow_timeout_in_minutes         = "" # Default is 4
      mesh_peering_enabled            = true  # Is this just for the hubs? make sure that it doesn't effect the spokes too.
#     resource_group_creation_enabled = false # default is true
      resource_group_lock_enabled     = false
#     resource_group_lock_name        = "" # string
#     resource_group_tags             = optional(map(string))
      route_table_name                = "westus-hub-rt-primary" #need to add route_table_name_firewall or keep variable as is?
      routing_address_space           = ["10.77.0.0/16"]
#     hub_router_ip_address           = "" # string
#     tags = {                        = # ??optional(map(string), {})      
      
#     route_table_entries_firewall = {
#      {
#        name                          = "" #string
#        address_prefix                = "" #string
#        next_hop_type                 = "" #string
#    
#        has_bgp_override              = false # optional(bool, false)
#        next_hop_ip_address           = ""    # optional(string)
#      },
#      {
#        name                          = "" #string
#        address_prefix                = "" #string
#        next_hop_type                 = "" #string
#    
#        has_bgp_override              = false # optional(bool, false)
#        next_hop_ip_address           = ""    # optional(string)        
#      }
#    }
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
#    subnets = {
#      bastion = {
#        name             = "AzureBastionSubnet"
#        address_prefixes = ["10.0.0.64/26"]
#        nat_gateway = {
#          id = ""
#        }
#        private_endpoint_network_policies_enabled = false # default is true
#        private_link_service_network_policies_enabled = false # default is true
#        route_table = {
#          id = "" # optional, string
#          assign_generated_route_table = false
#        }
#        service_endpoints = "" # set, string
#        service_endpoint_policy_ids = "" # set, sring
#        delegations = {
#          name = "" # string
#          service_delegation = {
#            name = "" # string
#            actions = "" # list, string
#          }
#        }
#      }
#      gateway = {
#        name             = "GatewaySubnet"
#        address_prefixes = ["10.0.0.128/27"]
#        route_table = {
#          assign_generated_route_table = false
#        }
#      }
#      user = {
#        name             = "hub-user-subnet"
#        address_prefixes = ["10.0.2.0/24"]
#      }
#    }
#  }
      firewall = {
        sku_name              = "AZFW_Hub" # or AZFW_VNet
        sku_tier              = "Premium" # 'Basic', 'Standard', 'Premium'
        subnet_address_prefix = "10.77.0.0/26"
#        firewall_policy_id    = "" # optional(string, null)
        name                  = "westus-pfw-hub-primary" #Must be named 'AzureFirewallSubnet'? # optional(string)
#        private_ip_ranges    = "" # optional(list(string))
#        subnet_route_table_id= "" # optional(string)
#        tags                 = "" # optional(list(string))
        zones                 = ["1", "2", "3"] # optional(list(string))
        default_ip_configuration = {
          public_ip_config = {
#            ip_version = "IPv4" # optional(string)
            name  = "pip-pfw-westus-hub-primary" # optional(string)
#            sku_tier = "" # 'Regional' or 'Global' # optional(string, "Regional")
#            zones = ["1", "2", "3"] # optional(set(string))
          }
        }
#        management_ip_configuration = {
#          public_ip_config = {
#            ip_version = "IPv4" # optional(string)
#            name  = "pip-pfw-westus-hub-primary" # optional(string)
#            sku_tier = "" # optional(string, "Regional")
#            zones = ["1", "2", "3"] # optional(set(string))
#          }
#        }
        firewall_policy = { 
          name                              = "westus-hub-policy-primary"  # configure separate module or add in here.
          sku                               = "Standard" # optional(string, "Standard")
#          auto_learn_private_ranges_enabled = false # optional(bool)
#          base_policy_id                    = "" # optional(string)
          dns = {
#            proxy_enabled = true # optional(bool, false)
            servers       = ["10.100.0.1", "10.100.0.2"] # optional(list(string))
#          threat_intelligence_mode          = "Alert" # optional(string, "Alert")
#          private_ip_ranges                 = "" # optional(list(string))
#          threat_intelligence_allowlist     = {
#            fqdns = "" # optional(set(string))
#            ip_addresses = "" #optional(set(string))                           
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
