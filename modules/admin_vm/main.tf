resource "azurerm_network_security_group" "this" {
  count = var.create_admin_vm ? 1 : 0

  name                = "nsg-${var.snet_admin_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "ssh_from_hub_bastion" {
  count = var.create_admin_vm && var.hub_azure_bastion_subnet_prefix != null ? 1 : 0

  name                        = "Allow-SSH-From-Hub-Bastion"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.hub_azure_bastion_subnet_prefix
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[0].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  count = var.create_admin_vm ? 1 : 0

  subnet_id                 = var.admin_subnet_id
  network_security_group_id = azurerm_network_security_group.this[0].id
}

resource "azurerm_network_interface" "this" {
  count = var.create_admin_vm ? 1 : 0

  name                = "nic-${var.admin_vm_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.admin_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.admin_private_ip_address
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  count = var.create_admin_vm ? 1 : 0

  name                            = var.admin_vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.admin_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.this[0].id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  lifecycle {
    precondition {
      condition     = !var.create_admin_vm || var.admin_ssh_public_key != null
      error_message = "admin_ssh_public_key is required when create_admin_vm is true."
    }
  }
}
