resource "azurerm_route_table" "this" {
  count = var.enable_udr_to_hub_firewall ? 1 : 0

  name                = "rt-${var.name_prefix}-${var.env}-to-hub-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_route" "default_to_hub_firewall" {
  count = var.enable_udr_to_hub_firewall ? 1 : 0

  name                   = "default-to-hub-firewall"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.hub_firewall_private_ip

  lifecycle {
    precondition {
      condition     = var.hub_firewall_private_ip != null
      error_message = "hub_firewall_private_ip is required when enable_udr_to_hub_firewall is true."
    }
  }
}

resource "azurerm_subnet_route_table_association" "aca_infra" {
  count = var.enable_udr_to_hub_firewall ? 1 : 0

  subnet_id      = var.aca_infra_subnet_id
  route_table_id = azurerm_route_table.this[0].id
}

resource "azurerm_subnet_route_table_association" "admin" {
  count = var.create_admin_vm && var.enable_udr_to_hub_firewall ? 1 : 0

  subnet_id      = var.admin_subnet_id
  route_table_id = azurerm_route_table.this[0].id
}
