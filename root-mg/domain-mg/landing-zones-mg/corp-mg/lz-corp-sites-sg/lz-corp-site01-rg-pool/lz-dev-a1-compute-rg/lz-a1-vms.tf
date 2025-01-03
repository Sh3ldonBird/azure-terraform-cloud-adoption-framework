module "USWP1App01" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.15.1"

  location                           = azurerm_resource_group.spoke1.location
  name                               = "USWP1App01" 
  resource_group_name                = azurerm_resource_group.spoke1.name
  zone                               = 1
  admin_username                     = "root"
  generate_admin_password_or_ssh_key = false

  admin_ssh_keys = [{
    public_key = tls_private_key.key.public_key_openssh
    username   = "adminuser"
  }] 

  os_type  = "linux"
  sku_size = "Standard_B1s"

  network_interfaces = {
    network_interface_1 = {
      name = "internal"
      ip_configurations = {
        ip_configurations_1 = {
          name                          = "internal"
          private_ip_address_allocation = "Dynamic"
          private_ip_subnet_resource_id = module.spoke1_vnet.subnets["spoke1-subnet"].resource_id
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference = {
    offer     = "0001-com-ubuntu-server-jammy"
    publisher = "Canonical"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

module "vm_spoke2" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.15.1"

  location                           = azurerm_resource_group.spoke2.location
  name                               = "vm-spoke2"
  resource_group_name                = azurerm_resource_group.spoke2.name
  zone                               = 1
  admin_username                     = "adminuser"
  generate_admin_password_or_ssh_key = false

  admin_ssh_keys = [{
    public_key = tls_private_key.key.public_key_openssh
    username   = "adminuser"
  }]

  os_type  = "linux"
  sku_size = "Standard_B1s"

  network_interfaces = {
    network_interface_1 = {
      name = "nic"
      ip_configurations = {
        ip_configurations_1 = {
          name                          = "nic"
          private_ip_address_allocation = "Dynamic"
          private_ip_subnet_resource_id = module.spoke2_vnet.subnets["spoke2-subnet"].resource_id
          create_public_ip_address      = true
          public_ip_address_name        = "vm1-pip"
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference = {
    offer     = "0001-com-ubuntu-server-jammy"
    publisher = "Canonical"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

output "virtual_networks" {
  value = module.hub_mesh.virtual_networks
}
