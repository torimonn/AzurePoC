resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "aca_infra" {
  name                 = var.snet_aca_infra_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.snet_aca_infra_prefixes

  delegation {
    name = "delegation-container-apps"

    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "private_endpoint" {
  name                 = var.snet_private_endpoint_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.snet_private_endpoint_prefixes

  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "admin" {
  count = var.create_admin_vm ? 1 : 0

  name                 = var.snet_admin_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.snet_admin_prefixes
}
