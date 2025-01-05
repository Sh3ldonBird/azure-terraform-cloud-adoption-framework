# Compute Variables
variable "vm_info" {
  description = "Configuration info for each VM"
  type        = map(object({
    name                = string
    network_interface_1 = optional(string)
  }))
}

# Network Variables
variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = string
}

variable "subnet_address_spaces" {
  description = "Address prefixes for the subnets in the VNet"
  type        = map(string)
}

# Resource Group Variables
variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
}