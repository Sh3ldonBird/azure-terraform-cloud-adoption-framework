### Compute Variables
variable "vm_info" {
  description = "Naming convention for each VM"
  type = map(object({
    name                = string
    network_interface_1 = optional(string)  # Optional field
  }))
  default = {
    IISFE = {
      name                = "USWP1IISFE01"
      network_interface_1 = "USWP1IISFE01-ifconfig1"  # Directly define the value
    }
    AppServer = {
      name = "USWP1APP01"
    }
    DBServer = {
      name = "USWP1SQL01"
    }
  }
}

### Network Variables
variable "vnet_address_spaces" {
  description = "Address spaces for VNets"
  type        = map(string)
  default     = {
    hub_vnet   = "10.77.0.0/22"
    hub_routing_space = "10.77.0.0/16"
    spoke_vnet = "192.168.0.0/16"
  }
}

variable "subnet_address_spaces" {
  description = "Subnet address prefixes"
  type        = map(map(string))  # Nested map for flexibility
  default = {
    hub_vnet = {
      azure_firewall_subnet        = "10.77.0.0/26"
      azure_firewall_management    = "10.77.0.64/26"
      shared_services_subnet       = "10.77.1.0/24"
    }
    spoke_vnet = {
      app_subnet                   = "192.168.7.0/24"
      db_subnet                    = "192.168.2.0/24"
    }
  }
}
### Identity Variables
variable "shared_identity" {
    description = "identity to share between the three VMs and otehr resources like the Azure Key Vault"
    type        = map(map(string))
    default = {
        shared_identity = {
            name = "user01"
        }
    }
}
### Resource Group Variables
# Prefix for resource group names
variable "prefix" {
  description = "The naming convention prefix for all resource groups (e.g., lz-corpsite01)"
  type        = string
  default     = "lz-corpsite01"
}

### rg postfix for resource group names
variable "postfix" {
  description = "Appends ""-rg"" to the end of each resource group."
  type        = string
  default     = "-rg"
}

### Metadata Variables
# Azure region
variable "region" {
  description = "Azure location/region for the resource groups"
  type        = string
  default     = {
    primary = "West US"
    secondary = "Central US"
}

# Tags for all resource groups
variable "tags" {
  description = "Tags to apply to resource groups (key-value pairs)"
  type        = map(string)
  default     = {
    "environment" = "dev"
    "owner"       = "madmanwithakeyboard"
  }
}
