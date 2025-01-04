# Prefix for resource group names
variable "prefix" {
  description = "The naming convention prefix for all resource groups (e.g., lz-corpsite01)"
  type        = string
  default     = "lz-corpsite01"
}

# rg postfix for resource group names
variable "prefix" {
  description = "Appends ""-rg"" to the end of each resource group."
  type        = string
  default     = "-rg"
}


# Azure region
variable "location" {
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
    "environment" = "production"
    "owner"       = "CloudOpsTeam"
  }
}
