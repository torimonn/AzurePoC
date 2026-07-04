locals {
  public_network_access_enabled = var.enable_key_vault_private_only_access ? false : var.key_vault_public_network_access_enabled
  network_default_action        = var.enable_key_vault_private_only_access ? "Deny" : var.key_vault_network_default_action
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  count = var.create_key_vault ? 1 : 0

  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.key_vault_sku_name
  rbac_authorization_enabled    = true
  public_network_access_enabled = local.public_network_access_enabled
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  purge_protection_enabled      = var.key_vault_purge_protection_enabled
  tags                          = var.tags

  network_acls {
    bypass         = var.key_vault_network_bypass
    default_action = local.network_default_action
  }
}

resource "azurerm_private_endpoint" "key_vault" {
  count = var.create_key_vault ? 1 : 0

  name                = "pe-${var.key_vault_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.this[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.key_vault_private_dns_zone_id]
  }
}
