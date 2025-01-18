# TODO
# Convert variables entered to reference the root variable.tf (rename compute-rg.tf?) file to make more modular.

######################################################################################################
# Cookie Cutter Build for Windows VM with security best practices in mind
#
# Documentation used:
#
# https://azure.github.io/Azure-Verified-Modules/indexes/terraform/
#
# https://github.com/Azure/terraform-azurerm-avm-res-compute-diskencryptionset
# https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault
# https://github.com/Azure/terraform-azurerm-avm-res-managedidentity-userassignedidentity/tree/main
# https://github.com/Azure/terraform-azurerm-avm-res-compute-virtualmachine/blob/main/variables.tf
######################################################################################################

terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116, < 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# tflint-ignore: terraform_module_provider_declaration, terraform_output_separate, terraform_variable_separate
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.3.0"

  availability_zones_filter = true
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions_by_name) - 1
  min = 0
}

resource "random_integer" "zone_index" {
  max = length(module.regions.regions_by_name[local.deployment_region].zones)
  min = 1
}

module "get_valid_sku_for_deployment_region" {
  source = "../../modules/sku_selector"

  deployment_region = local.deployment_region
}
data "resource_group_name" "existing_rg" {
  name = var.resource_group_name
}

# vm_infor resource definition


#resource "azurerm_virtual_network" "this_vnet" {
#  address_space       = ["10.0.0.0/16"]
#  location            = azurerm_resource_group.this_rg.location
#  name                = module.naming.virtual_network.name_unique
#  resource_group_name = azurerm_resource_group.this_rg.name
#  tags                = local.tags
#}

#resource "azurerm_subnet" "this_subnet_1" {
#  address_prefixes     = ["10.0.1.0/24"]
#  name                 = "${module.naming.subnet.name_unique}-1"
#  resource_group_name  = azurerm_resource_group.this_rg.name
#  virtual_network_name = azurerm_virtual_network.this_vnet.name
#}
#
#resource "azurerm_subnet" "this_subnet_2" {
#  address_prefixes     = ["10.0.2.0/24"]
#  name                 = "${module.naming.subnet.name_unique}-2"
#  resource_group_name  = azurerm_resource_group.this_rg.name
#  virtual_network_name = azurerm_virtual_network.this_vnet.name
#}

/* Uncomment this section if you would like to include a bastion resource with this example.
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.this_rg.name
  virtual_network_name = azurerm_virtual_network.this_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "bastionpip" {
  name                = module.naming.public_ip.name_unique
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = module.naming.bastion_host.name_unique
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name

  ip_configuration {
    name                 = "${module.naming.bastion_host.name_unique}-ipconf"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastionpip.id
  }
}
*/

data "azurerm_client_config" "current" {}

# how do i share this identity across multiple VMs?
resource "azurerm_user_assigned_identity" "example_identity" {
  location            = var.azurerm_resource_group.identity_rg.location
  name                = module.naming.user_assigned_identity.name_unique # Keep naming module in play or use variable in root.
  resource_group_name = var.azurerm_resource_group.identity_rg.name
  tags                = var.tags
}

module "avm_res_keyvault_vault" {
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  version             = "=0.9.1"
  tenant_id           = data.azurerm_client_config.current.tenant_id # configure further?
  name                = module.naming.key_vault.name_unique # Keep naming module in play or use variable in root
  resource_group_name = var.azurerm_resource_group.identity_rg.name
  location            = var.azurerm_resource_group.identity_rg.location
  network_acls = {
    default_action = "Allow"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }

  tags = local.tags
}
# Define all VMs in this manner and then create variables, outputs, main.tf's etc. to pull in all data and use one module main.tf
module "USWP1IISFE01" {
  source = "../../"
  #source = "Azure/avm-res-compute-virtualmachine/azurerm"
  #version = "0.17.0

  enable_telemetry    = var.enable_telemetry
  location            = var.azurerm_resource_group.compute_rg.location
  resource_group_name = var.azurerm_resource_group.compute_rg.name
  os_type             = "Windows"
  name                = var.vm_info.IISFE.name # module.naming.virtual_machine.name_unique
  sku_size            = module.get_valid_sku_for_deployment_region.sku # research
  zone                = random_integer.zone_index.result # fix resource

  generated_secrets_key_vault_secret_config = {
    key_vault_resource_id          = module.avm_res_keyvault_vault.resource_id
    expiration_date_length_in_days = 30 
    name                           = "example-password-secret-name"
    tags = {
      test_tag = "test_tag_value"
    }
  }

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.example_identity.id]
  }
  os_disk = {
    caching =
    storage_account_type = 
  }
  network_interfaces = {
    network_interface_1 = {
      name = "USWP1IISFE01-NIC1" #module.naming.network_interface.name_unique
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "USWP1IISFE01-NIC1-configuration" #var.vm_info.IISFE.network_interface_1 # why isn't it linking?
          create_public_ip_address      = true
          private_ip_address            = "192.168.7.10"
          private_ip_address_allocation = "Static"
          private_ip_address_version    = "IPv4"
#          private_ip_subnet_resource_id = azurerm_subnet.this_subnet_1.id
#          public_ip_address_resource_id = "?" 
      application_security_groups = {
        asg_1 = {
          application_security_group_resource_id = "" # I have to create NSG's then ASG's first to define them on this NIC.
            }
          }
      network_security_groups = {
        nsg_1 = {
          network_security_group_resource_id = "" # I have to create NSG's then ASG's first to define them on this NIC.
            }
      dns_servers = ["10.100.0.1","10.100.0.2"]

          }
        }
      }
    }
  }

  role_assignments_system_managed_identity = {
    role_assignment_1 = {
      scope_resource_id          = module.avm_res_keyvault_vault.resource_id
      role_definition_id_or_name = "Key Vault Secrets Officer"
      description                = "Assign the Key Vault Secrets Officer role to the virtual machine's system managed identity"
      principal_type             = "ServicePrincipal"
    }
  }

  role_assignments = {
    role_assignment_2 = {
      principal_id               = data.azurerm_client_config.current.client_id
      role_definition_id_or_name = "Virtual Machine Contributor"
      description                = "Assign the Virtual Machine Contributor role to the deployment user on this virtual machine resource scope."
      principal_type             = "ServicePrincipal"
    }
  }

  tags = {
    scenario = "windows_w_rbac_and_managed_identity"
  }

  winrm_listeners = [{ protocol = "Http" }]

  depends_on = [
    module.avm_res_keyvault_vault
  ]
}
